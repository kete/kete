# Search class isn't an ActiveRecord descendent
# refactoring to make search_controller stuff move to search model
# has only just started, so this is limited
class Search < ActiveRecord::Base
  def self.view_as_types
    types = Array.new
    types << ['', I18n.t('search_model.browse_default')]
    types << ['choice_hierarchy', I18n.t('search_model.choice_hierarchy')] if ExtendedField.find_by_label('categories')
    types << ['map', I18n.t('search_model.map')] if File.exist?(File.join(RAILS_ROOT, 'config/gmaps_api_key.yml'))
    types
  end

  def self.view_as_types_as_options(current, show_inherit = true)
    options = String.new
    options += "<option value='inherit'>#{I18n.t('search_model.view_as_types_as_options.inherit')}</option>" if show_inherit
    Search.view_as_types.each do |type|
      options += "<option value='#{type[0]}'#{" selected='selected'" if type[0] == current}>#{type[1]}</option>"
    end
    options
  end

  def self.boolean_operators
    ['and', 'or', 'not']
  end

  def self.date_types
    ['last_modified', 'date']
  end

  def self.sort_types
    ['title'] + date_types
  end

  def self.all_sort_types(sort_type, action, with_relevance = false)
    # not ideal, but the only way to get access that I know of
    new.sort_type_options_for(sort_type, action, with_relevance)
  end

  # Each saved search belongs to a user. People who are logged
  # out have theirs stored in the session until they login
  belongs_to :user

  # Each search needs a user, title, and url is work
  validates_presence_of :user, :title, :url

  # The URL should be unique. If it exists, we should be updating it instead
  # Also, it should be scoped to the user, so that other users with the same search work ok
  validates_uniqueness_of :url, scope: :user_id

  # First sort by the updated_at. This gets updated when a same search is made
  # When updated_at values are identical (when you login, multiple ones are added
  # at once), then sort by the id desc, the order they were entered
  default_scope order: 'updated_at desc, id desc'

  attr_accessor :zoom_db, :pqf_query

  def initialize(*args)
    @pqf_query = PqfQuery.new
    super
  end

  def sort_type_options_for(sort_type, action, with_relevance = false)
    with_relevance = with_relevance || (action == 'for' ? true : false)

    sort_type = sort_type(action: action, user_specified: sort_type, default: 'none')

    sort_type_options = String.new
    full_sort_types = with_relevance ? ['relevance'] + Search.sort_types : Search.sort_types

    full_sort_types.each do |type|
      if type == 'relevance'
        sort_type_options += '<option class="none" value="none"'
      else
        sort_type_options += "<option class=\"#{type}\" value=\"#{type}\""
      end
      sort_type_options += ' selected="selected"' if !sort_type.nil? && type == sort_type
      sort_type_options += '>' + I18n.t("search_model.#{type}") + '</option>'
    end
    sort_type_options
  end

  def sort_type(options = {})
    sort_type = options[:user_specified] || options[:default]

    # if this is an "all" search
    # sort by date last modified, i.e. oai_datestamp
    # if this rss, we want last_modified to be taken into account
    sort_type = 'last_modified' if options[:action] == 'rss' || (sort_type == 'none' && (options[:search_terms].nil? && options[:action] == 'all'))

    sort_type
  end

  def update_sort_direction_value_for_pqf_query(requested, sort_type = nil)
    sort_type = @pqf_query.sort_spec if sort_type.blank?

    date_types = Search.date_types

    @pqf_query.direction_value = 2 if (date_types.include?(sort_type) && (requested.nil? || requested != 'reverse')) || (!date_types.include?(sort_type) && !requested.nil? && requested == 'reverse')
  end

  def add_sort_to_query_if_needed(options = {})
    sort_type = sort_type(default: 'none',
                          user_specified: options[:user_specified],
                          action: options[:action],
                          search_terms: options[:search_terms])

    return @pqf_query if sort_type == 'none'

    update_sort_direction_value_for_pqf_query(options[:direction], sort_type)

    @pqf_query.sort_spec = sort_type
  end
end
