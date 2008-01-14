# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  # this allows for turning off sanitizing before save
  # and validates_as_sanitized_html
  # such as the case that a sysadmin wants to include a form
  attr_accessor :do_not_sanitize
  # sanitize our descriptions and extended_content for security
  acts_as_sanitized :fields => [:index_page_extra_side_bar_html, :extended_content]

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
      these_class_items = self.send("#{class_plural}").find_disputed
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
    [['Use site default', ''],
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

  protected
  # before save filter
  def urlify_name
    return if name.blank?
    formatted_name = name.to_s.gsub(/ /, '_').
      gsub(/-/,'_').
      downcase
    self.urlified_name = formatted_name
  end
end
