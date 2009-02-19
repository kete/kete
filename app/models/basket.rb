# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  # we use these for who can see what
  MEMBER_LEVEL_OPTIONS = [[I18n.t('basket_model.basket_member'), 'at least member'],
                          [I18n.t('basket_model.basket_moderator'), 'at least moderator'],
                          [I18n.t('basket_model.basket_admin'), 'at least admin'],
                          [I18n.t('basket_model.site_admin'), 'at least site admin']]

  USER_LEVEL_OPTIONS = [[I18n.t('basket_model.all_users'), 'all users']] + MEMBER_LEVEL_OPTIONS

  ALL_LEVEL_OPTIONS = [[I18n.t('basket_model.all_users'), 'all users']] + [[I18n.t('basket_model.logged_in'), 'logged in']] + MEMBER_LEVEL_OPTIONS

  # this allows for turning off sanitizing before save
  # and validates_as_sanitized_html
  # such as the case that a sysadmin wants to include a form
  attr_accessor :do_not_sanitize
  # sanitize our descriptions and extended_content for security
  acts_as_sanitized :fields => [:index_page_extra_side_bar_html]

  # Kieran Pilkington, 2008-07-09
  # remove the roles from a basket before destroying it to prevent problems later on
  before_destroy :remove_users_and_roles

  # Kieran Pilkington, 2008/08/19
  # setup our default baskets on application load, rather than each request
  cattr_accessor :site_basket, :help_basket, :about_basket, :documentation_basket, :standard_baskets
  @@site_basket = find(1)
  @@help_basket = find(HELP_BASKET)
  @@about_basket = find(ABOUT_BASKET)
  @@documentation_basket = find(DOCUMENTATION_BASKET)
  @@standard_baskets = [1, HELP_BASKET, ABOUT_BASKET, DOCUMENTATION_BASKET]
  after_save :reset_basket_class_variables
  before_destroy :reset_basket_class_variables

  # Kieran Pilkington, 2008/08/18
  # Store how many baskets have privacy controls enabled to determine
  # whether Site basket should keep its privacy browsing controls on
  # putting in the wrapper respond_to? logic so that upgrades of older Kete sites works
  if Basket.columns.collect { |c| c.name }.include?('show_privacy_controls')
    named_scope :should_show_privacy_controls, :conditions => { :show_privacy_controls => true }
    cattr_accessor :privacy_exists
    @@privacy_exists = (Basket.should_show_privacy_controls.count > 0)
    after_save :any_privacy_enabled_baskets?
    after_destroy :any_privacy_enabled_baskets?
  end
  # set up authorization plugin
  acts_as_authorizable

  # this gives us a settings hash per basket
  # that we can use for preferences
  acts_as_configurable

  # everything falls under one basket or another
  # we have a default basket for the site
  # can't use delete_all, throws off versioning
  # ZOOM_CLASSES.each do |zoom_class|
  #  has_many zoom_class.tableize.to_sym, :dependent => :destroy
  # end
  has_many :topics, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :documents, :dependent => :destroy
  has_many :videos, :dependent => :destroy
  has_many :audio_recordings, :dependent => :destroy
  has_many :still_images, :dependent => :destroy
  has_many :web_links, :dependent => :destroy

  # a topic may be the designated index page for it's basket
  has_one :index_topic, :class_name => 'Topic', :foreign_key => 'index_for_basket_id'

  # each basket was made by someone (admin or otherwise)
  belongs_to :creator, :class_name => 'User'

  # imports are processes to bring in content to a basket
  has_many :imports, :dependent => :destroy

  # each basket can have multiple feeds displayed in the sidebar
  has_many :feeds, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  # DEPRECIATED - urlified_name handles things correctly
  # and our xml escaping does the rest for plain old name attribute
  # don't allow special characters in label that will break our xml
  # validates_format_of :name, :with => /^[^\'\"<>\:\&,\?\}\{\/\\]*$/, :message => ": \', \\, /, &, \", <, and > characters aren't allowed"

  # check the quality of submitted html
  validates_as_sanitized_html :index_page_extra_side_bar_html

  # we have an urlified_name attribute that hold the urlified version of the basket name
  before_save :urlify_name

  # Walter McGinnis, 2008-05-10
  # old versions of items have to updated to not point at non-existing basket
  before_destroy :clear_item_version_foreign_keys

  def update_index_topic(index_topic)
    if !index_topic.nil? and index_topic.is_a?(Topic)
      self.index_topic = index_topic
    elsif index_topic == 'destroy'
      self.index_topic = nil
    end
    self.save
  end

  # stuff related to taggings in a basket

  # it's easy to get a basket's topics tag_counts
  # but we want all zoom_class's totals added together
  # special case is site basket
  # want to grab all tags from across all baskets
  def tag_counts_array(options = {}, private_tags=false)
    tag_limit = !options[:limit].nil? ? options[:limit] : self.index_page_number_of_tags
    tag_order = !options[:order].nil? ? options[:order] : self.index_page_order_tags_by
    tag_direction = ['asc', 'desc'].include?(options[:direction]) ? options[:direction] : (tag_order == 'alphabetical' ? 'asc' : 'desc')

    unless !tag_limit || tag_limit > 0 # false = no limit, 0 = no tags
      return Array.new
    end

    case tag_order
    when 'alphabetical'
      find_tag_order = "tags.name #{tag_direction}"
    when 'latest'
      find_tag_order = "taggings.created_at #{tag_direction}"
    when 'number'
      find_tag_order = "count #{tag_direction}"
    else
      find_tag_order = 'Rand()'
    end

    @tag_counts_hash = Hash.new

    ZOOM_CLASSES.each do |zoom_class|
      zoom_set = (self.id == 1) ? zoom_class.constantize : self.send(zoom_class.tableize)
      zoom_class_tag_hash = zoom_set.tag_counts({:limit => tag_limit, :order => find_tag_order}, private_tags)

      # if exists in @tag_counts, update count with added number
      [:public, :private].each do |privacy|
        zoom_class_tag_hash[privacy.to_sym].each do |tag|
          tag_key = tag.id.to_s
          if !@tag_counts_hash.include?(tag_key)
            @tag_counts_hash[tag_key] = { :id => tag.id,
                                          :name => tag.name,
                                          :public_taggings_count => (privacy == :public) ? tag.count : 0,
                                          :private_taggings_count => (privacy == :private) ? tag.count : 0,
                                          :total_taggings_count => tag.count }
          else
            @tag_counts_hash[tag_key][:public_taggings_count] += tag.count if privacy == :public
            @tag_counts_hash[tag_key][:private_taggings_count] += tag.count if privacy == :private
            @tag_counts_hash[tag_key][:total_taggings_count] += tag.count
          end
        end
      end
    end

    # take the hash and create an ordered array by amount of taggings
    # with nested hashes for attributes
    @tag_counts_array = Array.new
    @tag_counts_hash.keys.each do |tag_key|
      @tag_counts_array << @tag_counts_hash[tag_key]
    end

    # We need to sort through the results here as well as in the query
    # because we joined several ZOOM_CLASSES so they'll be out of order
    case tag_order
    when 'alphabetical'
      @tag_counts_array = @tag_counts_array.sort_by { |tag_hash| tag_hash[:name] }
      @tag_counts_array = @tag_counts_array.reverse if tag_direction == 'desc'
    when 'latest'
      @tag_counts_array = @tag_counts_array.sort_by { |tag_hash| tag_hash[:id] }
      @tag_counts_array = @tag_counts_array.reverse if tag_direction == 'desc'
    when 'number'
      @tag_counts_array = @tag_counts_array.sort_by { |tag_hash| tag_hash[:total_taggings_count] }
      @tag_counts_array = @tag_counts_array.reverse if tag_direction == 'desc'
    else
      @tag_counts_array = @tag_counts_array.sort_by { rand }
    end

    # the query limits per ZOOM_CLASS, not overall combined results, so we do that here
    @tag_counts_array = @tag_counts_array[0..(tag_limit - 1)] unless !tag_limit # when tag_limit is false, we return all

    return @tag_counts_array
  end

  # attribute options methods
  def show_flagging_as_options(site_basket)
    current_show_flagging_value = self.settings[:show_flagging] || site_basket.settings[:show_flagging] || 'all users'
    select_options = self.array_to_options_list_with_defaults(USER_LEVEL_OPTIONS,current_show_flagging_value)
  end

  def show_add_links_as_options(site_basket)
    current_show_add_links_value = self.settings[:show_add_links] || site_basket.settings[:show_add_links] || 'all users'
    select_options = self.array_to_options_list_with_defaults(USER_LEVEL_OPTIONS,current_show_add_links_value)
  end

  def show_action_menu_as_options(site_basket)
    current_show_actions_value = self.settings[:show_action_menu] || site_basket.settings[:show_action_menu] || 'all users'
    select_options = self.array_to_options_list_with_defaults(USER_LEVEL_OPTIONS,current_show_actions_value)
  end

  def show_discussion_as_options(site_basket)
    current_show_discussion_value = self.settings[:show_discussion] || site_basket.settings[:show_discussion] || 'all users'
    select_options = self.array_to_options_list_with_defaults(USER_LEVEL_OPTIONS,current_show_discussion_value)
  end

  def side_menu_ordering_of_topics_as_options(site_basket)
    current_value = self.settings[:side_menu_ordering_of_topics] || site_basket.settings[:side_menu_ordering_of_topics] || 'updated_at'
    options_array = [['Latest', 'latest'],['Alphabetical', 'alphabetical']]
    select_options = self.array_to_options_list_with_defaults(options_array,current_value)
  end

  def private_file_visibility_as_options(site_basket)
    current_value = self.settings[:private_file_visibility] || site_basket.settings[:private_file_visibility] || 'at least member'
    select_options = self.array_to_options_list_with_defaults(MEMBER_LEVEL_OPTIONS,current_value)
  end

  def private_file_visibilty_selected_or_default(value, site_basket)
    current_value = self.settings[:private_file_visibility] || site_basket.settings[:private_file_visibility] || 'at least member'
    value == current_value
  end

  # If setting is nil, be conservative.
  def allow_non_member_comments?
    allow_non_member_comments === true
  end


  # Privacy related methods, taking into account inheritance from Site Basket

  def show_privacy_controls_with_inheritance?
    (self.show_privacy_controls == true || (self.show_privacy_controls.nil? && self.site_basket.show_privacy_controls == true))
  end

  def private_default_with_inheritance?
    (self.private_default == true || (self.private_default.nil? && self.site_basket.private_default == true))
  end

  def file_private_default_with_inheritance?
    (self.file_private_default == true || (self.file_private_default.nil? && self.site_basket.file_private_default == true))
  end

  def private_file_visibility_with_inheritance
    self.settings[:private_file_visibility] || self.site_basket.settings[:private_file_visibility] || "at least member"
  end

  def additional_footer_content_with_inheritance
    (!settings[:additional_footer_content].nil? && !self.settings[:additional_footer_content].squish.blank? ? self.settings[:additional_footer_content] : self.site_basket.settings[:additional_footer_content])
  end

  def replace_existing_footer_with_inheritance?
    (self.settings[:replace_existing_footer] == true || (self.settings[:replace_existing_footer].nil? && self.site_basket.settings[:replace_existing_footer] == true))
  end

  def memberlist_policy_or_default
    current_value = self.settings[:memberlist_policy] || self.site_basket.settings[:memberlist_policy] || 'at least admin'
    select_options = self.array_to_options_list_with_defaults(ALL_LEVEL_OPTIONS, current_value, false)
  end

  def array_to_options_list_with_defaults(options_array, default_value, site_admin=true)
    select_options = String.new
    options_array.each do |option|
      label = option[0]
      value = option[1]
      next if label == I18n.t('basket_model.site_admin') && !site_admin
      select_options += "<option value=\"#{value}\""
      if default_value == value
        select_options += " selected=\"selected\""
      end
      select_options += ">" + label + "</option>"
    end
    select_options
  end

  # attribute options methods
  def self.link_to_index_topic_as_options
    [[I18n.t('basket_model.details_and_comments'), 'full topic and comments'],
     [I18n.t('basket_model.only_details'), 'full topic'],
     [I18n.t('basket_model.only_comments'), 'comments'],
     [I18n.t('basket_model.dont_link'), '']]
  end

  def self.recent_topics_as_options
    [[I18n.t('basket_model.recent_dont_show'), ''],
     [I18n.t('basket_model.recent_as_summaries'), 'summaries'],
     [I18n.t('basket_model.recent_as_headlines'), 'headlines']]
  end

  def self.archives_as_options
    [[I18n.t('basket_model.archives_dont_show'), ''],
     [I18n.t('basket_model.archives_by_type'), 'by type']]
  end

  def self.image_as_options
    [[I18n.t('basket_model.image_dont_show'), ''],
     [I18n.t('basket_model.image_latest'), 'latest'],
     [I18n.t('basket_model.image_random'), 'random']]
  end

  def self.order_tags_by_options
    [[I18n.t('basket_model.tags_ordered_most_popular'), 'number'],
     [I18n.t('basket_model.tags_ordered_by_name'), 'alphabetical'],
     [I18n.t('basket_model.tags_ordered_latest'), 'latest'],
     [I18n.t('basket_model.tags_ordered_random'), 'random']]
  end

  def self.tags_as_options
    [[I18n.t('basket_model.tags_as_categories'), 'categories'],
     [I18n.t('basket_model.tags_as_tag_cloud'), 'tag cloud']]
  end

  def moderation_select_options
    select_options = String.new
    [[I18n.t('basket_model.moderate_before_approved'), true],
     [I18n.t('basket_model.moderate_on_flagged'), false]].each do |option|
      label = option[0]
      value = option[1]
      select_options += "<option value=\"#{value}\""
      if fully_moderated? == value
        select_options += " selected=\"selected\""
      end
      select_options += ">" + label + "</option>"
    end
    select_options
  end

  def fully_moderated?
    settings[:fully_moderated].blank? ? DEFAULT_POLICY_IS_FULL_MODERATION : settings[:fully_moderated]
  end

  # if we don't have any moderators specified
  # find admins for basket
  # if no admins for basket, go with basket 1 (site) admins
  # if no admins for site, go with any site_admins
  def moderators_or_next_in_line
    moderators = self.has_moderators

    if moderators.size == 0
      moderators = self.has_admins

      if moderators.size == 0
        moderators = Basket.find(:first).has_admins

        if moderators.size == 0
          moderators = Basket.find(:first).has_site_admins
        end
      end
    end
    moderators
  end

  def all_disputed_revisions
    @all_disputed_revisions = Array.new

    ZOOM_CLASSES.each do |zoom_class|
      class_plural = zoom_class.tableize
      these_class_items = self.send("#{class_plural}").find_disputed(self.id)
      @all_disputed_revisions += these_class_items
    end

    # sort by flagged_at
    @all_disputed_revisions.sort_by { |item| item.flagged_at }
  end

  def possible_themes
    @possible_themes = Array.new
    themes_dir = Dir.new(THEMES_ROOT)
    themes_dir.each do |listing|
      path_to_theme_dir = THEMES_ROOT + '/' + listing
      if File.directory?(path_to_theme_dir) and !['.', '..', '.svn'].include?(listing)
        # needs to have at least a stylesheets directory
        # and an images directory with a sample in it under it
        @possible_themes << listing if File.exists?(path_to_theme_dir + '/stylesheets') and File.exists?(path_to_theme_dir + '/images/sample.jpg')
      end
    end
    @possible_themes
  end

  def font_family_select_options
    select_options = String.new
    [[I18n.t('basket_model.font_use_theme_default'), ''],
     [I18n.t('basket_model.font_sans_serif'), 'sans-serif'],
     [I18n.t('basket_model.font_serif'), 'serif']].each do |option|
      label = option[0]
      value = option[1]
      select_options += "<option value=\"#{value}\""
      if !self.settings[:theme_font_family].blank? and self.settings[:theme_font_family] == value
        select_options += " selected=\"selected\""
      end
      select_options += ">" + label + "</option>"
    end
    select_options
  end

  # find if we should let users access the basket contact form
  # get the baskets setting or if nil, get it from the site basket
  def allows_contact_with_inheritance?
    (self.settings[:allow_basket_admin_contact] == true || (self.settings[:allow_basket_admin_contact].class == NilClass && @@site_basket.settings[:allow_basket_admin_contact] == true))
  end

  # return a boolean for whether basket join requests (with inheritance) are enabled
  # open / request = true
  # closed = false
  def allows_join_requests_with_inheritance?
    ['open', 'request'].include?(self.join_policy_with_inheritance)
  end

  # get the current basket join policy. If nil, use the site baskets
  def join_policy_with_inheritance
    (!self.settings[:basket_join_policy].blank?) ? self.settings[:basket_join_policy] : self.site_basket.settings[:basket_join_policy]
  end

  # get a list of administrators (including site administrators
  # if the current basket is the site basket)
  # uses auto-generated methods from the authorization plugin
  def administrators
    if self == self.site_basket
      self.has_site_admins_or_admins
    else
      self.has_admins
    end
  end

  # we need at least one site admin at all times
  def more_than_one_site_admin?
    self.has_site_admins.size > 1
  end

  # we need at least one admin in a basket at all times
  def more_than_one_basket_admin?
    self.has_admins.size > 1
  end

  def delete_roles_for(user)
    self.accepted_roles.each do |role|
      user.has_no_role(role.name, self)
    end
  end

  protected

  include FriendlyUrls

  # before save filter
  def urlify_name
    return if name.blank?

    formatted_name = name.to_s

    self.urlified_name = format_friendly_unicode_for(formatted_name,
                                                     :demarkator => "_",
                                                     :at_start => false,
                                                     :at_end => false)
  end

  private

  # when a basket is to be deleted
  # we have to update all versions for items that used to point
  # at the basket in question (but were previously moved out of basket)
  # we point them at the site basket and add to the item's version comment
  def clear_item_version_foreign_keys
    # work through the versions for each zoom_class
    ZOOM_CLASSES.each do |zoom_class|
      versions = Module.class_eval(zoom_class + '::Version').find_all_by_basket_id(self)
      versions.each do |version|
        new_version_comment = version.version_comment.nil? ? String.new : version.version_comment + '. '
        new_version_comment += I18n.t('basket_model.now_in_site_basket', :basket_name => self.name)

        version.update_attributes(:basket_id => 1, :version_comment => new_version_comment )
      end
    end
  end

  # when a basket is to be deleted
  # we have to remove the roles assigned to it
  # otherwise authorizable tries to get the basket which no longer exists
  # when called in user.basket_permissions
  def remove_users_and_roles
    self.accepted_roles.each do |role|
      # authentication plugin's accepts_no_role was problematic
      # rolling our own
      role.users.each { |user| user.drop(role) }
      role.reload
      role.destroy if role.users.size == 0
    end
  end

  # reset the baskets class variable if its one of those we cache
  def reset_basket_class_variables
    return unless @@standard_baskets.include?(self.id)
    case self.id
    when 1
      @@site_basket = Basket.find(1)
    when HELP_BASKET
      @@help_basket = Basket.find(HELP_BASKET)
    when ABOUT_BASKET
      @@about_basket = Basket.find(ABOUT_BASKET)
    when DOCUMENTATION_BASKET
      @@documentation_basket = Basket.find(DOCUMENTATION_BASKET)
    end
  end

  # when we create, update, or destroy, we recalcutate the amount of
  # baskets with privacy controls enabled
  def any_privacy_enabled_baskets?
    @@privacy_exists = (Basket.should_show_privacy_controls.count > 0)
  end

  # James - 2008-12-10
  # Prevent site basket from being deleted
  before_destroy :prevent_site_basket_destruction

  def prevent_site_basket_destruction
    if self == @@site_basket
      raise I18n.t('basket_model.cannot_delete_site')
      false
    else
      true
    end
  end

end
