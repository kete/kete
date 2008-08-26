# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  # we use these for who can see what
  MEMBER_LEVEL_OPTIONS = [['Basket member', 'at least member'],
                          ['Basket moderator', 'at least moderator'],
                          ['Basket admin', 'at least admin'],
                          ['Site admin', 'at least site admin']]

  USER_LEVEL_OPTIONS = [['All users', 'all users']] + MEMBER_LEVEL_OPTIONS

  # this allows for turning off sanitizing before save
  # and validates_as_sanitized_html
  # such as the case that a sysadmin wants to include a form
  attr_accessor :do_not_sanitize
  # sanitize our descriptions and extended_content for security
  acts_as_sanitized :fields => [:index_page_extra_side_bar_html]

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
  named_scope :should_show_privacy_controls, :conditions => { :show_privacy_controls => true }
  cattr_accessor :privacy_exists
  @@privacy_exists = (Basket.should_show_privacy_controls.count > 0)
  after_save :any_privacy_enabled_baskets?
  after_destroy :any_privacy_enabled_baskets?

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

  # imports are processes to bring in content to a basket
  has_many :imports, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  # don't allow special characters in label that will break our xml
  validates_format_of :name, :with => /^[^\'\"<>\:\&,\?\}\{\/\\]*$/, :message => ": \', \\, /, &, \", <, and > characters aren't allowed"

  # check the quality of submitted html
  validates_as_sanitized_html :index_page_extra_side_bar_html

  # we have an urlified_name attribute that hold the urlified version of the basket name
  before_save :urlify_name

  # Walter McGinnis, 2008-05-10
  # old versions of items have to updated to not point at non-existing basket
  before_destroy :clear_item_version_foreign_keys

  # Kieran Pilkington, 2008-07-09
  # remove the roles from a basket before destroying it to prevent problems later on
  before_destroy :remove_users_and_roles

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
  def tag_counts_array
    tag_limit = self.index_page_number_of_tags

    @tag_counts_hash = Hash.new

    if tag_limit > 0
      tag_order = nil
      case self.index_page_order_tags_by
      when 'alphabetical'
        tag_order = 'tags.name'
      when 'latest'
        tag_order = 'taggings.created_at desc'
      when 'number'
        tag_order = 'count desc'
      when 'random'
        tag_order = 'Rand()'
      end
      ZOOM_CLASSES.each do |zoom_class|
        zoom_class_tag_counts = nil
        if self.id == 1
          zoom_class_tag_counts = Module.class_eval(zoom_class).tag_counts(:limit => tag_limit, :order => tag_order)
        else
          zoom_class_tag_counts = self.send(zoom_class.tableize).tag_counts(:limit => tag_limit, :order => tag_order)
        end

        # if exists in @tag_counts, update count with added number
        zoom_class_tag_counts.each do |tag|
          tag_key = tag.id.to_s
          if !@tag_counts_hash.include?(tag_key)
            @tag_counts_hash[tag_key] = { :id => tag.id, :name => tag.name, :taggings_count => tag.count }
          else
            @tag_counts_hash[tag_key][:taggings_count] +=  tag.count
          end
        end
      end
    else
      return Array.new
    end
    # take the hash and create an ordered array by amount of taggings
    # with nested hashes for attributes
    @tag_counts_array = Array.new
    @tag_counts_hash.keys.each do |tag_key|
      @tag_counts_array << @tag_counts_hash[tag_key]
    end

    # can only resort by alpha and number
    # random doesn't need resorting
    # and latest should be covered in the query
    case self.index_page_order_tags_by
    when 'alphabetical'
      @tag_counts_array = @tag_counts_array.sort_by { |tag_hash| tag_hash[:name]}
    when 'number'
      @tag_counts_array = @tag_counts_array.sort_by { |tag_hash| tag_hash[:taggings_count]}
      @tag_counts_array = @tag_counts_array.reverse
    when 'random'
      @tag_counts_array = @tag_counts_array.sort_by { rand }
    end

    @tag_counts_array = @tag_counts_array[0..(tag_limit - 1)]
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

  def array_to_options_list_with_defaults(options_array, default_value)
    select_options = String.new
    options_array.each do |option|
      label = option[0]
      value = option[1]
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
    [['Full details and comments', 'full topic and comments'],
     ['Only full details', 'full topic'],
     ['Only comments', 'comments'],
     ['Don\'t link', '']]
  end

  def self.recent_topics_as_options
    [['Don\'t show them', ''],
     ['Summaries (blog style)', 'summaries'],
     ['Headlines (news style)', 'headlines']]
  end

  def self.archives_as_options
    [['Don\'t show them', ''],
     ['By type', 'by type']]
  end

  def self.image_as_options
    [['No image', ''],
     ['Latest', 'latest'],
     ['Random', 'random']]
  end

  def self.order_tags_by_options
    [['Number of items', 'number'],
     ['Alphabetical', 'alphabetical'],
     ['Latest', 'latest'],
     ['Random', 'random']]
  end

  def self.tags_as_options
    [['Categories', 'categories'],
     ['Tag Cloud', 'tag cloud']]
  end

  def moderation_select_options
    select_options = String.new
    [['moderator views before item approved', true],
     ['moderation upon being flagged', false]].each do |option|
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

  # Private file visibility, taking into account inheritance from
  # site basket if not set locally
  def private_file_visibility
    self.settings[:private_file_visibility] || Basket.find(1).settings[:private_file_visibility] || "at least member"
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
    [['Use theme default', ''],
     ['Sans Serif (Arial, Helvetica, and the like)', 'sans-serif'],
     ['Serif (Times New Roman, etc.)', 'serif']].each do |option|
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

  # If setting is nil, be conservative.
  def allow_non_member_comments?
    allow_non_member_comments === true
  end

  def private_default_with_inheritance?
    (self.private_default == true || (self.private_default.nil? && @@site_basket.private_default == true))
  end

  def show_privacy_controls_with_inheritance?
    (self.show_privacy_controls == true || (self.show_privacy_controls.nil? && @@site_basket.show_privacy_controls == true))
  end

  # Get the roles this Basket has
  def roles
    Role.find_all_by_authorizable_type_and_authorizable_id('Basket', self)
  end

  protected
  # before save filter
  def urlify_name
    return if name.blank?

    formatted_name = name.to_s

    # we may want to make this based on a constant
    # in the future
    chars_to_be_replaced = [' ', '-', '.']
    chars_to_be_replaced.each do |char|
      formatted_name = formatted_name.gsub(char, '_')
    end

    formatted_name = formatted_name.downcase

    self.urlified_name = formatted_name
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
        new_version_comment += "This version was in #{self.name} basket, but that basket has been deleted and no longer exists on the site, now this version is put in default site basket."

        version.update_attributes(:basket_id => 1, :version_comment => new_version_comment )
      end
    end
  end

  # when a basket is to be deleted
  # we have to remove the roles assigned to it
  # otherwise authorizable tries to get the basket which no longer exists
  # when called in user.get_basket_permissions
  def remove_users_and_roles
    roles.each do |role|
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
end
