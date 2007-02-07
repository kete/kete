require 'digest/sha1'
class User < ActiveRecord::Base
  # methods related to handling the xml kept in extended_content column
  include ExtendedContent

  # this is where we handle contributions of different kinds
  has_many :contributions, :order => 'created_at', :dependent => :delete_all
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through

  # we want to have plain contributor vs creator for our contributor_roles
  # we also want to insert versions, but only list by distinct contributor_role
  # rather than for every single version
  # since we are going to use our z39.50 search to accumulate our contributed or created objects
  # this is mainly for convenience methods rather than finders
  ZOOM_CLASSES.each do |zoom_class|
    has_many "created_#{zoom_class.tableize}".to_sym, :through => :contributions, :source => zoom_class.tableize.singularize.to_sym, :order => 'created_at'
    has_many "contributed_#{zoom_class.tableize}".to_sym, :through => :contributions, :source => zoom_class.tableize.singularize.to_sym, :order => 'created_at'
  end

  # Virtual attribute for the contribution.version join model
  # a hack to be able to pass it in
  # see topics_controller update action for example
  attr_accessor :version

  # set up authorization plugin
  acts_as_authorized_user
  acts_as_authorizable

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password

  after_save :add_as_member_to_default_basket

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
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
    "#{id}"+Unicode::normalize_KD("-"+login+"-").downcase.gsub(/[^a-z0-9\s_-]+/,'').gsub(/[\s_-]+/,'-')[0..-2]
  end

  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end

    # after_save
    def add_as_member_to_default_basket
      basket = Basket.find(1)
      self.has_role('member',basket)
    end
end
