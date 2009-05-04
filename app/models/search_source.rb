class SearchSource < ActiveRecord::Base
  acts_as_list

  validates_presence_of :title
  validates_presence_of :source_type
  validates_presence_of :base_url
  validates_presence_of :limit
  validates_presence_of :cache_interval

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

end
