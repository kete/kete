# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  scope :except_certain_baskets, lambda { |baskets| where("id not in (?) AND status = 'approved'", baskets) }

  def self.settings
    # * EOIN: we are pretty sure this is not called - raise an exception to be sure
    # * FIXME: this is temporary and should be removed before we go into production
    raise 'died in Basket.settings'
  end

  # EOIN: TEMP: just while we are figuring out how this works
  def setting(name, *args)
    fail "Basket#setting expected just a name but we got the name '#{name}' and these extras: #{args}" unless args.empty?
    BasketSettings.get(name, *args)
  end

  def to_param
    urlified_name
  end

  # we use these for who can see what
  def self.member_level_options
    [
      [I18n.t('basket_model.basket_member'), 'at least member'],
      [I18n.t('basket_model.basket_moderator'), 'at least moderator'],
      [I18n.t('basket_model.basket_admin'), 'at least admin'],
      [I18n.t('basket_model.site_admin'), 'at least site admin']]
  end

  def self.user_level_options
    [[I18n.t('basket_model.all_users'), 'all users']] +
      Basket.member_level_options
  end

  def self.all_level_options
    [[I18n.t('basket_model.all_users'), 'all users']] +
      [[I18n.t('basket_model.logged_in'), 'logged in']] +
      Basket.member_level_options
  end

  def self.level_value_from(key)
    Basket.all_level_options.select { |v, k| k == key }.first.first
  end

  # profile forms, these should correspond to actions in the controller
  # really this would be nicer if it came from reflecting on the baskets_controller class
  def self.forms_options
    [
      [I18n.t('basket_model.basket_new_or_edit'), 'edit'],
      [I18n.t('basket_model.basket_appearance'), 'appearance'],
      [I18n.t('basket_model.basket_homepage_options'), 'homepage_options']]
  end

  # Editable Basket Attributes (copy from the basket database fields)
  EDITABLE_ATTRIBUTES = %w{
    index_page_redirect_to_all index_page_topic_is_entire_page
    index_page_link_to_index_topic_as index_page_basket_search index_page_image_as
    index_page_tags_as index_page_number_of_tags index_page_order_tags_by
    index_page_recent_topics_as index_page_number_of_recent_topics index_page_archives_as
    index_page_extra_side_bar_html private_default file_private_default allow_non_member_comments
    show_privacy_controls do_not_sanitize feeds_attributes }

  # Editable Basket Settings
  EDITABLE_SETTINGS = %w{
    fully_moderated moderated_except private_file_visibility browse_view_as
    sort_order_default sort_direction_reversed_default disable_site_recent_topics_display
    basket_join_policy memberlist_policy import_archive_set_policy allow_basket_admin_contact private_item_notification
    private_item_notification_show_title private_item_notification_show_short_summary
    theme_font_family header_image theme show_action_menu show_discussion show_flagging
    show_add_links side_menu_number_of_topics side_menu_ordering_of_topics side_menu_direction_of_topics
    additional_footer_content do_not_sanitize_footer_content replace_existing_footer }

  # Basket settings that are always editable or come under a parent option
  NESTED_FIELDS = %w{
    name status creator_id do_not_sanitize moderated_except
    sort_direction_reversed_default private_item_notification_show_title
    private_item_notification_show_short_summary index_page_link_to_index_topic_as
    index_page_recent_topics_as index_page_tags_as index_page_order_tags_by
    show_action_menu show_discussion show_flagging show_add_links
    side_menu_number_of_topics side_menu_ordering_of_topics side_menu_direction_of_topics
    do_not_sanitize_footer_content replace_existing_footer }

  # Kieran Pilkington, 2008-07-09
  # remove the roles from a basket before destroying it to prevent problems later on
  before_destroy :remove_users_and_roles

  # Kieran Pilkington, 2010-05-14
  # Make a quick class level var for some assignments below (to prevent multiple queries)
  # Note: NOT to be used outside this class! Used only when the application is loaded
  all_baskets = all

  def self.documentation_basket
    b = Basket.where(name: 'Documentation').first
    b or raise('Failed to find the required Documentation basket')
  end

  def self.about_basket
    b = Basket.where(name: 'About').first
    b or raise('Failed to find the required About basket')
  end

  def self.help_basket
    b = Basket.where(name: 'Help').first
    b or raise('Failed to find the required Help basket')
  end

  def self.site_basket
    b = Basket.where(name: 'Site').first
    b or raise('Failed to find the required Site basket')
  end

  # EOIN: possible future refactoring: make this return the actual baskets ???
  def self.standard_basket_ids
    [site_basket.id, help_basket.id, about_basket.id, documentation_basket.id]
  end

  def role(name)
    Role.where(name: name).where(authorizable_type: 'Basket').where(authorizable_id: id).last
  end

  def documentation_basket
    Basket.documentation_basket
  end

  def about_basket
    Basket.about_basket
  end

  def help_basket
    Basket.help_basket
  end

  def site_basket
    Basket.site_basket
  end

  def standard_basket_ids
    Basket.standard_basket_ids
  end

  # Kieran Pilkington, 2008/08/18
  # Store how many baskets have privacy controls enabled to determine
  # whether Site basket should keep its privacy browsing controls on
  # putting in the wrapper respond_to? logic so that upgrades of older Kete sites works
  if Basket.columns.any? { |c| c.name == 'show_privacy_controls' }
    scope :should_show_privacy_controls, lambda { where(show_privacy_controls: true) }
    cattr_accessor :privacy_exists
    @@privacy_exists = all_baskets.any? { |basket| basket.show_privacy_controls? }
    after_save :any_privacy_enabled_baskets?
    after_destroy :any_privacy_enabled_baskets?
  end
  # set up authorization plugin
  acts_as_authorizable

  # everything falls under one basket or another
  # we have a default basket for the site
  # can't use delete_all, throws off versioning
  # ZOOM_CLASSES.each do |zoom_class|
  #  has_many zoom_class.tableize.to_sym, :dependent => :destroy
  # end
  has_many :topics, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :audio_recordings, dependent: :destroy
  has_many :still_images, dependent: :destroy
  has_many :web_links, dependent: :destroy

  # a topic may be the designated index page for it's basket
  has_one :index_topic, class_name: 'Topic', foreign_key: 'index_for_basket_id'

  # each basket was made by someone (admin or otherwise)
  belongs_to :creator, class_name: 'User'

  # imports are processes to bring in content to a basket
  has_many :imports, dependent: :destroy

  # each basket can have multiple feeds displayed in the sidebar
  has_many :feeds, dependent: :destroy
  accepts_nested_attributes_for :feeds, reject_if: proc { |attributes| attributes['url'].blank? }

  # each basket may have a profile (or in the future, possibly more than one)
  # that declares the rules of what options a basket admin may see/set
  # as opposed to a site administrator
  has_many :profile_mappings, as: :profilable, dependent: :destroy
  has_many :profiles, through: :profile_mappings

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  # DEPRECIATED - urlified_name handles things correctly
  # and our xml escaping does the rest for plain old name attribute
  # don't allow special characters in label that will break our xml
  # validates_format_of :name, :with => /^[^\'\"<>\:\&,\?\}\{\/\\]*$/, :message => ": \', \\, /, &, \", <, and > characters aren't allowed"

  # we have an urlified_name attribute that hold the urlified version of the basket name
  before_save :urlify_name

  # Walter McGinnis, 2008-05-10
  # old versions of items have to updated to not point at non-existing basket
  before_destroy :clear_item_version_foreign_keys

  def update_index_topic(index_topic)
    if !index_topic.nil? && index_topic.is_a?(Topic)
      self.index_topic = index_topic
    elsif index_topic == 'destroy'
      self.index_topic = nil
    end
    save
  end

  # stuff related to taggings in a basket

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  # it's easy to get a basket's topics tag_counts
  # but we want all zoom_class's totals added together
  # special case is site basket
  # want to grab all tags from across all baskets
  def tag_counts_array(options = {})
    tag_limit = !options[:limit].nil? ? options[:limit] : index_page_number_of_tags
    tag_order = !options[:order].nil? ? options[:order] : index_page_order_tags_by
    tag_direction = ['asc', 'desc'].include?(options[:direction]) ? options[:direction] : (tag_order == 'alphabetical' ? 'asc' : 'desc')
    private_tags = options[:allow_private] || false

    return [] unless !tag_limit || tag_limit > 0 # false = no limit, 0 = no tags

    case tag_order
    when 'alphabetical'
      find_tag_order = "tags.name #{tag_direction}"
    when 'latest'
      find_tag_order = "taggings.created_at #{tag_direction}"
    when 'number'
      find_tag_order = "taggings_count #{tag_direction}"
    else
      # EOIN: the value here in old kete is :random but rails doesn't support that now (if it ever did)
      # TODO: do we really need to specify that the order should be random?
      find_tag_order = 'RANDOM()' # RAND() is mysql specific, on postgres it would be RANDOM()
    end

    tag_offset = (((options[:page] || 1) - 1) * tag_limit)

    conditions = "taggings.context = 'public_tags'"
    conditions += "taggings.context IN ('public_tags', 'private_tags')" if private_tags
    conditions += " AND taggings.basket_id = #{id}" unless self == site_basket

    tags = ActsAsTaggableOn::Tag.select('tags.id, tags.name, count(taggings.id) AS taggings_count')
                                .where(conditions)
                                .group('taggings.tag_id, tags.id, tags.name, taggings.created_at')
                                .joins(:taggings)
                                .order(find_tag_order)
                                .offset(tag_offset)
                                .limit(tag_limit)

    tags.map do |tag|
      {
        id: tag.id,
        name: tag.name,
        to_param: tag.to_param,
        total_taggings_count: tag.taggings_count
      }
    end
  end

  def tag_publicity_conditions(private_tags = false)
    conditions = "taggings.context = 'public_tags'"
    conditions = "taggings.context IN ('public_tags', 'private_tags')" if private_tags
    conditions += " AND taggings.basket_id = #{id}" unless self == site_basket
    conditions
  end

  def tag_counts_total(options)
    private_tags = options[:allow_private] || false

    tag_options = {
      select: 'distinct taggings.tag_id',
      joins: 'INNER JOIN taggings ON (tags.id = taggings.tag_id)',
      conditions: "taggings.context = 'public_tags'"
    }
    tag_options[:conditions] = "taggings.context IN ('public_tags', 'private_tags')" if private_tags
    tag_options[:conditions] += " AND taggings.basket_id = #{id}" unless self == site_basket

    ActsAsTaggableOn::Tag.count(tag_options)
  end

  # attribute options methods
  # TODO clean this up using define_method (meta programming magic)
  def show_flagging_as_options(site_basket, default = nil)
    current_show_flagging_value = default || setting(:show_flagging) || site_basket.setting(:show_flagging) || 'all users'
    select_options = array_to_options_list_with_defaults(Basket.user_level_options, current_show_flagging_value)
  end

  def show_add_links_as_options(site_basket, default = nil)
    current_show_add_links_value = default || setting(:show_add_links) || site_basket.setting(:show_add_links) || 'all users'
    select_options = array_to_options_list_with_defaults(Basket.user_level_options, current_show_add_links_value)
  end

  def show_action_menu_as_options(site_basket, default = nil)
    current_show_actions_value = default || setting(:show_action_menu) || site_basket.setting(:show_action_menu) || 'all users'
    select_options = array_to_options_list_with_defaults(Basket.user_level_options, current_show_actions_value)
  end

  def show_discussion_as_options(site_basket, default = nil)
    current_show_discussion_value = default || setting(:show_discussion) || site_basket.setting(:show_discussion) || 'all users'
    select_options = array_to_options_list_with_defaults(Basket.user_level_options, current_show_discussion_value)
  end

  def side_menu_ordering_of_topics_as_options(site_basket, default = nil)
    current_value = default || setting(:side_menu_ordering_of_topics) || site_basket.setting(:side_menu_ordering_of_topics) || 'updated_at'
    options_array = [['Latest', 'latest'], ['Alphabetical', 'alphabetical']]
    select_options = array_to_options_list_with_defaults(options_array, current_value)
  end

  def private_file_visibility_as_options(site_basket, default = nil)
    current_value = default || setting(:private_file_visibility) || site_basket.setting(:private_file_visibility) || 'at least member'
    select_options = array_to_options_list_with_defaults(Basket.member_level_options, current_value)
  end

  def private_file_visibilty_selected_or_default(value, site_basket)
    current_value = setting(:private_file_visibility) || site_basket.setting(:private_file_visibility) || 'at least member'
    value == current_value
  end

  # If setting is nil, be conservative.
  def allow_non_member_comments?
    allow_non_member_comments === true
  end

  # Privacy related methods, taking into account inheritance from Site Basket

  def show_privacy_controls_with_inheritance?
    (show_privacy_controls == true || (show_privacy_controls.nil? && site_basket.show_privacy_controls == true))
  end

  def private_default_with_inheritance?
    (private_default == true || (private_default.nil? && site_basket.private_default == true))
  end

  def file_private_default_with_inheritance?
    (file_private_default == true || (file_private_default.nil? && site_basket.file_private_default == true))
  end

  def private_file_visibility_with_inheritance
    setting(:private_file_visibility) || site_basket.setting(:private_file_visibility) || 'at least member'
  end

  def allow_non_member_comments_with_inheritance?
    (allow_non_member_comments == true || (allow_non_member_comments.nil? && site_basket.allow_non_member_comments == true))
  end

  def additional_footer_content_with_inheritance
    (!setting(:additional_footer_content).nil? && !setting(:additional_footer_content).to_s.squish.blank? ? setting(:additional_footer_content) : site_basket.setting(:additional_footer_content))
  end

  def replace_existing_footer_with_inheritance?
    (setting(:replace_existing_footer) == true || (setting(:replace_existing_footer).nil? && site_basket.setting(:replace_existing_footer) == true))
  end

  def memberlist_policy_or_default(default = nil)
    current_value = default || memberlist_policy_with_inheritance
    array_to_options_list_with_defaults(Basket.all_level_options, current_value, false)
  end

  def memberlist_policy_with_inheritance
    if !setting(:memberlist_policy).blank?
      setting(:memberlist_policy)
    elsif !site_basket.setting(:memberlist_policy).blank?
      site_basket.setting(:memberlist_policy)
    else
      'at least admin'
    end
  end

  def import_archive_set_policy_or_default(default = nil)
    current_value = default || import_archive_set_policy_with_inheritance
    array_to_options_list_with_defaults(Basket.member_level_options, current_value, false)
  end

  def import_archive_set_policy_with_inheritance
    if !setting(:import_archive_set_policy).blank?
      setting(:import_archive_set_policy)
    elsif !site_basket.setting(:import_archive_set_policy).blank?
      site_basket.setting(:import_archive_set_policy)
    else
      'at least admin'
    end
  end

  def browse_type_with_inheritance
    case setting(:browse_view_as)
    when 'inherit'
      site_basket.browse_type_with_inheritance
    when '' # if blank, return nil
      nil
    else
      setting(:browse_view_as)
    end
  end

  def private_item_notification_or_default(default = nil)
    current_value = default || setting(:private_item_notification) || site_basket.setting(:private_item_notification) || 'at least member'
    options = [[I18n.t('basket_model.private_item_notification_or_default.dont_send_notification'), 'do_not_email']] + Basket.member_level_options
    select_options = array_to_options_list_with_defaults(options, current_value, false, true)
  end

  def users_to_notify_of_private_item
    case setting(:private_item_notification)
    when 'at least member'
      has_site_admins_or_admins_or_moderators_or_members
    when 'at least moderator'
      has_site_admins_or_admins_or_moderators
    when 'at least admin'
      has_site_admins_or_admins
    else
      []
    end
  end

  def array_to_options_list_with_defaults(options_array, default_value, site_admin = true, pluralize = false)
    select_options = ''
    options_array.each do |option|
      label = option[0]
      value = option[1]
      next if label == I18n.t('basket_model.site_admin') && !site_admin
      select_options += "<option value=\"#{value}\""
      if default_value == value
        select_options += ' selected="selected"'
      end
      select_options += '>' + (pluralize ? label.pluralize : label) + '</option>'
    end
    select_options
  end

  # attribute options methods
  def self.link_to_index_topic_as_options
    [
      [I18n.t('basket_model.dont_link'), ''],
      [I18n.t('basket_model.details_and_comments'), 'full topic and comments'],
      [I18n.t('basket_model.only_details'), 'full topic'],
      [I18n.t('basket_model.only_comments'), 'comments']]
  end

  def self.recent_topics_as_options
    [
      [I18n.t('basket_model.recent_dont_show'), ''],
      [I18n.t('basket_model.recent_as_summaries'), 'summaries'],
      [I18n.t('basket_model.recent_as_headlines'), 'headlines']]
  end

  def self.archives_as_options
    [
      [I18n.t('basket_model.archives_dont_show'), ''],
      [I18n.t('basket_model.archives_by_type'), 'by type']]
  end

  def self.image_as_options
    [
      [I18n.t('basket_model.image_dont_show'), ''],
      [I18n.t('basket_model.image_latest'), 'latest'],
      [I18n.t('basket_model.image_random'), 'random']]
  end

  def self.order_tags_by_options
    [
      [I18n.t('basket_model.tags_ordered_most_popular'), 'number'],
      [I18n.t('basket_model.tags_ordered_by_name'), 'alphabetical'],
      [I18n.t('basket_model.tags_ordered_latest'), 'latest'],
      [I18n.t('basket_model.tags_ordered_random'), 'random']]
  end

  def self.tags_as_options
    [
      [I18n.t('basket_model.tags_as_categories'), 'categories'],
      [I18n.t('basket_model.tags_as_tag_cloud'), 'tag cloud']]
  end

  def moderation_select_options(default = nil)
    select_options = ''
    [
      [I18n.t('basket_model.moderate_before_approved'), true],
      [I18n.t('basket_model.moderate_on_flagged'), false]].each do |option|
      label = option[0]
      value = option[1]
      select_options += "<option value=\"#{value}\""
      if (default && (default == value.to_s || (default.blank? && value == false))) ||
         (!default && fully_moderated? == value)
        select_options += ' selected="selected"'
      end
      select_options += '>' + label + '</option>'
    end
    select_options
  end

  def fully_moderated?
    setting(:fully_moderated).blank? ? SystemSetting.default_policy_is_full_moderation : setting(:fully_moderated)
  end

  # if we don't have any moderators specified
  # find admins for basket
  # if no admins for basket, go with basket 1 (site) admins
  # if no admins for site, go with any site_admins
  def moderators_or_next_in_line
    moderators = has_moderators
    moderators = has_admins if moderators.size == 0
    moderators = Basket.site_basket.has_admins if moderators.size == 0
    moderators << Basket.site_basket.has_site_admins if moderators.size == 0 || SystemSetting.notify_site_admins_of_flaggings

    moderators.flatten.uniq
  end

  # all_disputed_revisions
  # all_reviewed_revisions
  # all_rejected_revisions
  %w{disputed reviewed rejected}.each do |type|
    define_method("all_#{type}_revisions") do
      revisions = ZOOM_CLASSES.collect do |zoom_class|
        send(zoom_class.tableize.to_sym).send("find_#{type}", id)
      end.flatten.compact
      revisions.sort_by { |item| item.flagged_at }
    end
  end

  def possible_themes
    @possible_themes = []
    themes_dir = Dir.new(THEMES_ROOT)
    themes_dir.each do |listing|
      path_to_theme_dir = THEMES_ROOT + '/' + listing
      if File.directory?(path_to_theme_dir) && !['.', '..', '.svn'].include?(listing)
        # needs to have at least a stylesheets directory
        # and an images directory with a sample in it under it
        @possible_themes << listing if File.exist?(path_to_theme_dir + '/stylesheets') && File.exist?(path_to_theme_dir + '/images/sample.jpg')
      end
    end
    @possible_themes
  end

  def font_family_select_options(default = nil)
    select_options = ''
    [
      [I18n.t('basket_model.font_use_theme_default'), ''],
      [I18n.t('basket_model.font_sans_serif'), 'sans-serif'],
      [I18n.t('basket_model.font_serif'), 'serif']].each do |option|
      label = option[0]
      value = option[1]
      select_options += "<option value=\"#{value}\""
      if (default && default == value) ||
         (!setting(:theme_font_family).blank? && setting(:theme_font_family) == value)
        select_options += ' selected="selected"'
      end
      select_options += '>' + label + '</option>'
    end
    select_options
  end

  # find if we should let users access the basket contact form
  # get the baskets setting or if nil, get it from the site basket
  def allows_contact_with_inheritance?
    (setting(:allow_basket_admin_contact) == true || (setting(:allow_basket_admin_contact).class == NilClass && site_basket.setting(:allow_basket_admin_contact) == true))
  end

  # return a boolean for whether basket join requests (with inheritance) are enabled
  # open / request = true
  # closed = false
  def allows_join_requests_with_inheritance?
    ['open', 'request'].include?(join_policy_with_inheritance)
  end

  # get the current basket join policy. If nil, use the site baskets
  def join_policy_with_inheritance
    !setting(:basket_join_policy).blank? ? setting(:basket_join_policy) : site_basket.setting(:basket_join_policy)
  end

  # get a list of administrators (including site administrators
  # if the current basket is the site basket)
  # uses auto-generated methods from the authorization plugin
  def administrators
    if self == site_basket
      has_site_admins_or_admins
    else
      has_admins
    end
  end

  # we need at least one site admin at all times
  def more_than_one_site_admin?
    has_site_admins.size > 1
  end

  # we need at least one admin in a basket at all times
  def more_than_one_basket_admin?
    has_admins.size > 1
  end

  def delete_roles_for(user)
    accepted_roles.each do |role|
      user.has_no_role(role.name, self)
    end
  end

  def related_images(type = :last)
    still_images.find_non_pending(type, PUBLIC_CONDITIONS) || {}
  end

  protected

  include FriendlyUrls

  # before save filter
  def urlify_name
    return if name.blank?

    formatted_name = name.to_s

    self.urlified_name = format_friendly_unicode_for(
      formatted_name,
      demarkator: '_',
      at_start: false,
      at_end: false
    )
  end

  def self.list_as_names_and_urlified_names
    all(select: 'name, urlified_name').collect { |basket| [basket.name, basket.urlified_name] }
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
        new_version_comment = version.version_comment.nil? ? '' : version.version_comment + '. '
        new_version_comment += I18n.t('basket_model.now_in_site_basket', basket_name: name)

        version.update_attributes(basket_id: 1, version_comment: new_version_comment)
      end
    end
  end

  # when a basket is to be deleted
  # we have to remove the roles assigned to it
  # otherwise authorizable tries to get the basket which no longer exists
  # when called in user.basket_permissions
  def remove_users_and_roles
    accepted_roles.each do |role|
      # authentication plugin's accepts_no_role was problematic
      # rolling our own
      role.users.each { |user| user.drop(role) }
      role.reload
      role.destroy if role.users.size == 0
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
    if self == site_basket
      raise I18n.t('basket_model.cannot_delete_site')
      false
    else
      true
    end
  end

  # Walter McGinnis, 2012-06-21
  # create redirect_registration if basket.urlified_name has changed
  # important this is called after urlify_name before_save
  before_update :register_redirect_if_necessary

  def register_redirect_if_necessary
    old_urlified_name = self.class.select('urlified_name').where(id: id).first.urlified_name
    if old_urlified_name != urlified_name
      RedirectRegistration.create!(source_url_pattern: "/#{old_urlified_name}/", target_url_pattern: "/#{urlified_name}/")
    end
  end
end
