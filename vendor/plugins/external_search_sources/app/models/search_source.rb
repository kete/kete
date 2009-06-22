class SearchSource < ActiveRecord::Base
  acts_as_list

  validates_presence_of :title, :source_type, :base_url, :limit, :cache_interval
  validates_format_of :base_url, :with => /^http:\/\/.*/, :message => I18n.t('search_source_model.requires_http')
  validates_numericality_of :limit, :only_integer => true
  validates_numericality_of :cache_interval, :only_integer => true

  cattr_accessor :acceptable_source_types
  @@acceptable_source_types = %w{ feed }

  validates_inclusion_of :source_type, :in => @@acceptable_source_types, :message => I18n.t('search_source_model.must_be_one_of', :types => @@acceptable_source_types.join(', '))

  default_scope :order => 'position ASC'

  acts_as_configurable

  after_save :store_or_syntax

  def or_syntax
    @or_syntax ||= self.settings[:or_syntax]
  end

  def or_syntax=(value)
    @or_syntax = value
  end

  def store_or_syntax
    self.settings[:or_syntax] = @or_syntax unless @or_syntax.blank?
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

  def parse_search_text(search_text)
    return search_text if or_syntax.blank?

    or_string = or_syntax[:case] == 'upper' ? 'OR' : 'or'
    case or_syntax[:position]
    when 'before'
      "#{or_string} #{search_text}"
    when 'after'
      "#{search_text} #{or_string}"
    when 'between'
      search_text.strip.gsub(/\s/, " #{or_string} ")
    else
      search_text
    end

    URI.escape(search_text, /\W/)
  end

  def source_url
    return I18n.t('search_source_model.source_url.not_fetched') if @search_text.nil?
    URI.escape(base_url) + @search_text
  end

  def more_link
    return I18n.t('search_source_model.more_link.not_fetched') if @search_text.nil?
    return source_url if more_link_base_url.blank?
    URI.escape(more_link_base_url) + @search_text
  end

  def sort_entries(entries)
    total = 0
    links = Array.new
    images = Array.new
    entries[0..(limit - 1)].each do |entry|
      if !entry.media_thumbnail.nil? || !entry.enclosure.nil?
        images << entry
      else
        links << entry
      end
      total += 1
    end
    { :total => total, :links => links, :images => images }
  end

  def fetch(search_text)
    @search_text = parse_search_text(search_text)

    feed = Feedzirra::Feed.fetch_and_parse(source_url)
    # In the case that the feed can't be parsed, it returns a Fixnum, so check
    # if the output is a Feedzirra object, and if not, return a blank array
    entries = feed.class.name =~ /Feedzirra/ ? feed.entries : []

    sort_entries(entries)
  end

end
