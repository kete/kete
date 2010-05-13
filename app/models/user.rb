require 'digest/sha1'
class User < ActiveRecord::Base
  # imports are processes to bring in content to a basket
  # they specify a topic type of thing they are importing
  # or a topic type for the item that relates groups of things
  # that they are importing
  has_many :imports, :dependent => :destroy

  # Walter McGinnis, 2007-03-23
  # added activation supporting code
  # it's use it set by REQUIRE_ACTIVATION in config/environment.rb
  # even if you have REQUIRE_ACTIVATION = false
  # the code in this file needs to be here to support it
  # we if false, we simple auto activate the user in user_observer
  # rather than sending the sign up email
  before_create :make_activation_code

  # Kieran Pilkington, 2008-07-09
  # remove the roles from a user before destroying it to prevent problems later on
  before_destroy :remove_roles

  # methods related to handling the xml kept in extended_content column
  include ExtendedContent

  # this is where we handle contributions of different kinds
  has_many :contributions, :order => 'created_at', :dependent => :delete_all
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through

  # Default license from acts_as_licensed
  belongs_to :license

  # we want to have plain contributor vs creator for our contributor_roles
  # we also want to insert versions, but only list by distinct contributor_role
  # rather than for every single version
  # since we are going to use our z39.50 search to accumulate our contributed or created objects
  # this is mainly for convenience methods rather than finders
  ZOOM_CLASSES.each do |zoom_class|
    has_many "created_#{zoom_class.tableize}".to_sym,
    :through => :contributions,
    :source => "created_#{zoom_class.tableize.singularize}".to_sym,
    :include => :basket,
    :order => "#{zoom_class.tableize}.created_at"

    has_many "contributed_#{zoom_class.tableize}".to_sym,
    :through => :contributions,
    :source => "contributed_#{zoom_class.tableize.singularize}".to_sym,
    :include => :basket,
    :order => "#{zoom_class.tableize}.created_at"
  end

  # Each user can have multiple portraits (images relating to their account)
  has_many :user_portrait_relations, :order => 'position', :dependent => :delete_all
  has_many :portraits, :through => :user_portrait_relations, :source => :still_image, :order => 'user_portrait_relations.position'

  # users can create baskets if the system setting is enabled to do so
  has_many :baskets, :class_name => 'Basket', :foreign_key => :creator_id

  # users can have many saved searches
  has_many :searches, :dependent => :destroy

  # Virtual attribute for the contribution.version join model
  # a hack to be able to pass it in
  # see topics_controller update action for example
  attr_accessor :version

  # set up authorization plugin
  acts_as_authorized_user
  acts_as_authorizable

  # Add association to license
  License.has_many :users, :dependent => :nullify

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  # For the security code
  attr_accessor :security_code, :security_code_confirmation

  # For accepting terms
  attr_accessor :agree_to_terms

  validates_presence_of     :login, :email
  validates_inclusion_of    :agree_to_terms, :in => ['1'], :if => :new_record?, :message => 'before you can sign up'
  validates_presence_of     :security_code,              :if => :new_record?
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  # Walter McGinnis, 2008-03-16
  # refining captcha to be more accessable (i.e. adding questions) and also make more sense to end user
  validates_confirmation_of :security_code,              :if => :new_record?, :message => lambda { I18n.t('user_model.failed_security_answer') }
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_format_of       :login, :with => /^[^\s]+$/
  validates_uniqueness_of   :login, :case_sensitive => false

  validates_inclusion_of :locale, :in => I18n.available_locales_with_labels.keys, :message => lambda { I18n.t('user_model.locale_incorrect', :locales => I18n.available_locales_with_labels.keys.join(', ')) }

  before_save :encrypt_password

  # Create the resolved name based on the display name or login
  before_save :display_name_or_login

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    # hide records with a nil activated_at
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
    # Walter McGinnis, 2007-06-08
    # can't login if they are banned
    u && u.authenticated?(password) && u.banned_at.nil? ? u : nil
  end

  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # James Stradling <james@katipo.co.nz>, 2008-04-17
  # Changes the activation flag on the model so duplicate activation emails
  # are not sent.
  # TODO: Clean this up.
  def notified_of_activation
    @activated = false
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # make ids look like this for urls
  # /7-my-title-for-topic-7/
  # i.e. /id-title/
  # rails strips the non integers after the id
  def to_param
    require 'unicode'
    "#{id}"+Unicode::normalize_KD("-"+user_name+"-").downcase.gsub(/[^a-z0-9\s_-]+/,'').gsub(/[\s_-]+/,'-')[0..-2]
  end

  # password reset related
  def forgot_password
    self.make_password_reset_code
    @forgotten_password = true
  end

  def reset_password
    # First update the password_reset_code before setting the
    # reset_password flag to avoid duplicate email notifications.
    update_attributes(:password_reset_code => nil)
    @reset_password = true
  end

  def recently_reset_password?
    @reset_password
  end

  def recently_forgot_password?
    @forgotten_password
  end

  def user_name
    self.resolved_name
  end

  def avatar
    @avatar ||= (self.portraits.first if !self.portraits.empty? && !self.portraits.first.thumbnail_file.file_private)
  end

  def show_email?
    extended_content_hash = self.xml_attributes_without_position
    @show_email = false
    if !extended_content_hash.blank? && !extended_content_hash["email_visible"].blank? && !extended_content_hash["email_visible"].to_s.match("xml_element_name") && extended_content_hash["email_visible"].strip == 'yes'
      @show_email = true
    end
    return @show_email
  end

  def accepts_emails?
    self.allow_emails == true
  end

  # we only need distinct items contributed to
  # because we have a polymorphic foreign key
  # this is tricky to do in sql,
  # at least without making it db specific
  def distinct_contributions
    @distinct_contributions = Array.new
    ZOOM_CLASSES.each do |zoom_class|
      self.send("created_#{zoom_class.tableize}".to_sym).each do |contribution|
        if !@distinct_contributions.include?(contribution)
          @distinct_contributions << contribution
        end
      end
      self.send("contributed_#{zoom_class.tableize}".to_sym).each do |contribution|
        if !@distinct_contributions.include?(contribution)
          @distinct_contributions << contribution
        end
      end
    end
    return @distinct_contributions
  end

  def add_checkbox
    # used by a form when adding user as member of a basket
    # where 0 is always going to be the starting value
    return 0
  end

  def add_as_member_to_default_baskets
    Basket.find_all_by_id(DEFAULT_BASKETS_IDS).each { |basket| self.has_role('member',basket) }
  end

  def basket_permissions
    select = "roles.id AS role_id, roles.name AS role_name, baskets.id AS basket_id, baskets.urlified_name AS basket_urlified_name, baskets.name AS basket_name"
    join = "INNER JOIN baskets on roles.authorizable_id = baskets.id"
    permissions = roles.find_all_by_authorizable_type('Basket', :select => select, :joins => join)

    permissions_hash = Hash.new
    permissions.each do |permission|
      p = permission.attributes
      permissions_hash[p['basket_urlified_name'].to_sym] = {
        :id => p['basket_id'].to_i,
        :role_id => p['role_id'].to_i,
        :role_name => p['role_name'],
        :basket_name => p['basket_name']
      }
    end
    permissions_hash
  end

  # For single role deletion
  # To delete all roles, use user.roles.delete_all
  def drop(role)
    # has_no_role(role.name, role.authorizable)
    # unlike has_no_role, doesn't destroy role
    # if role has no users
    roles.delete(role)
  end

  protected

  # supporting activation
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  # supporting password reset
  def make_password_reset_code
    self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def display_name_or_login
    self.resolved_name = !self.display_name.blank? ? self.display_name : self.login
  end

  private

  # when a user is to be deleted
  # we have to remove the roles assigned to it
  # otherwise authorizable tries to get the basket which no longer exists
  # when called in current_user.basket_permissions
  def remove_roles
    roles.delete_all
  end

end
