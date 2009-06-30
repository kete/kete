class SearchSource < ActiveRecord::Base
  acts_as_list

  validates_presence_of :title, :source_type
  validates_format_of :base_url, :with => /^http:\/\/.*/, :message => I18n.t('search_source_model.requires_http')
  validates_numericality_of :limit, :only_integer => true, :allow_blank => true
  validates_numericality_of :cache_interval, :only_integer => true, :allow_blank => true

  %w{ source_types source_targets limit_params }.each do |config|
    cattr_accessor "acceptable_#{config}".to_sym
    class_eval("@@acceptable_#{config} = ExternalSearchSources[config.to_sym]")
    validates_inclusion_of config.singularize.to_sym, :in => class_eval("@@acceptable_#{config}"), :allow_blank => (config == 'limit_params'),
                           :message => I18n.t('search_source_model.must_be_one_of', :types => class_eval("@@acceptable_#{config}.join(', ')"))
  end

  default_scope :order => 'position ASC'

  acts_as_configurable

  # in the case no limit is supplied, set a default one of 5
  before_save :set_limit

  # in the case that we turn on caching later,
  # lets set this by default even if not needed right now
  before_save :set_cache_interval

  # take the or syntax we have and set it when this record is saved
  after_save :store_or_syntax

  def or_syntax
    @or_syntax ||= self.settings[:or_syntax]
  end

  def or_syntax=(value)
    @or_syntax = value
  end

  def title_id
    title.gsub(/\W/, '_').downcase
  end

  def authorized_for?(args)
    case args[:action].to_sym
    when :move_higher
      !first?
    when :move_lower
      !last?
    else
      true
    end
  end

  def self.or_positions
    [ [I18n.t('search_source_model.or_positions.no_or_syntax'), 'none'],
      [I18n.t('search_source_model.or_positions.before_terms'), 'before'],
      [I18n.t('search_source_model.or_positions.between_terms'), 'between'],
      [I18n.t('search_source_model.or_positions.after_terms'), 'after'] ]
  end

  def self.or_case
    [ [I18n.t('search_source_model.or_case.doesnt_matter'), 'upper'],
      [I18n.t('search_source_model.or_case.uppercase'), 'upper'],
      [I18n.t('search_source_model.or_case.lowercase'), 'lower'] ]
  end

  def source_url
    return I18n.t('search_source_model.source_url.not_fetched') if @search_text.nil?
    URI.escape(base_url) + @search_text + @limit_string.to_s
  end

  def more_link
    return I18n.t('search_source_model.more_link.not_fetched') if @search_text.nil?
    return source_url if more_link_base_url.blank?
    URI.escape(more_link_base_url) + @search_text + @limit_string.to_s
  end

  def fetch(search_text, options = {})
    return { :total => 0 } if search_text.blank?

    parse_search_text(search_text)
    parse_limit_param(options)

    logger.debug "Getting search source results from: #{source_url}"

    feed = Feedzirra::Feed.fetch_and_parse(source_url)
    # In the case that the feed can't be parsed, it returns a Fixnum, so check
    # if the output is a Feedzirra object, and if not, return a blank array
    entries = feed.class.name =~ /Feedzirra/ ? feed.entries : []

    sort_entries(entries, options)
  end

  def self.import_from_yaml(yaml_file, options = {})
    options = { :verbose => true }.merge(options)

    attr_sets = YAML.load(File.open(yaml_file))
    attr_sets.each do |attrs|
      # Fixtures are returned as name => { value, .. }. We only need the values.
      attrs = attrs.last

      begin
        or_syntax = attrs.delete('or_syntax').split('_')
        puts attrs.inspect
        if attrs['base_url'].include?('[api_key]')
          raise "No API key provided for search source that requires one." unless options[:api_key]
          attrs['base_url'].gsub!('[api_key]', options[:api_key])
        end
        ss = SearchSource.new(attrs)
        ss.or_syntax = { :position => or_syntax[0], :case => or_syntax[1] }
        ss.save!
        p "Inserted search source: '#{attrs["title"]}'." if options[:verbose]
      rescue
        p "Inserting search source '#{attrs["title"]} failed: #{$!}."
      end
    end
  end

  private

  def set_limit
    self.limit = 5 if limit.blank?
  end

  def set_cache_interval
    self.cache_interval = 1440 if cache_interval.blank?
  end

  def store_or_syntax
    self.settings[:or_syntax] = @or_syntax unless @or_syntax.blank?
  end

  def parse_search_text(search_text)
    return search_text if or_syntax.blank?

    or_string = or_syntax[:case] == 'upper' ? 'OR' : 'or'
    search_text = case or_syntax[:position]
    when 'before'
      "#{or_string} #{search_text}"
    when 'after'
      "#{search_text} #{or_string}"
    when 'between'
      search_text.strip.gsub(/\s/, " #{or_string} ")
    else
      search_text
    end

    @search_text = URI.escape(search_text, /\W/)
  end

  def sort_entries(entries, options = {})
    total = 0
    links = Array.new
    images = Array.new
    entries[0..((options[:limit] || limit) - 1)].each do |entry|
      if !entry.media_thumbnail.nil? || !entry.enclosure.nil?
        images << entry
      else
        links << entry
      end
      total += 1
    end
    { :total => total, :links => links, :images => images }
  end

  def parse_limit_param(options = {})
    @limit_string = !limit_param.blank? ? "&#{limit_param}=#{(options[:limit] || limit).to_s}" : ''
  end

end
