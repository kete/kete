class ExtendedField < ActiveRecord::Base
  include ExtendedFieldsHelpers

  # Choices/enumerations
  has_many :choice_mappings, :as => :field
  has_many :choices, :through => :choice_mappings

  # find an extended field based on params[:extended_field]
  def self.from_id_or_label(id_or_label)
    self.first(:conditions => ['UPPER(label) = ?', id_or_label.upcase.gsub('_', ' ')]) || self.find_by_id(id_or_label)
  end

  # James - 2008-12-05
  # Ensure attributes that when changed could be potentially destructive on existing data cannot
  # be changed after the initial save.
  # When sufficient testing and conversion code as been added to handle all events relating to changing
  # these fields, this attributes can be made writeable again.
  attr_readonly :label, :ftype, :multiple

  acts_as_configurable

  after_save :store_topic_type

  def topic_type
    @topic_type ||= self.settings[:topic_type]
  end

  def topic_type=(value)
    @topic_type = value
  end

  def store_topic_type
    self.settings[:topic_type] = @topic_type unless @topic_type.blank?
  end

  after_save :store_circa

  def circa
    @circa ||= self.settings[:circa]
  end

  def circa?
    circa && circa.param_to_obj_equiv
  end

  def circa=(value)
    @circa = value
  end

  def store_circa
    self.settings[:circa] = @circa unless @circa.blank?
  end

  after_save :set_base_url

  def base_url
    @base_url ||= self.settings[:base_url]
  end

  def base_url=(value)
    @base_url = value
  end

  def set_base_url
    self.settings[:base_url] = @base_url unless @base_url.blank?
  end

  def pseudo_choices
    choices.collect { |c| [c.label, c.id] }
  end

  def pseudo_choices=(array_of_ids)
    logger.debug "ARRAY_OF_IDS = #{array_of_ids.inspect}"
    self.choices = []
    self.choices = array_of_ids.collect { |id| Choice.find(id) }
  end

  has_many :topic_type_to_field_mappings, :dependent => :destroy
  # if we ever use this association, we'll want to add a test for it
  has_many :topic_type_forms, :through => :topic_type_to_field_mappings, :source => :topic_type, :order => 'position'

  has_many :content_type_to_field_mappings, :dependent => :destroy
  # if we ever use this association, we'll want to add a test for it
  has_many :content_type_forms, :through => :content_type_to_field_mappings, :source => :content_type, :order => 'position'

  validates_presence_of :label
  validates_uniqueness_of :label, :case_sensitive => false

  # don't allow special characters in label that will break our xml
  validates_format_of :label, :with => /^[^\'\":<>\&,\/\\\?\.]*$/, :message => lambda { I18n.t('extended_field_model.invalid_chars', :invalid_chars => ": \', \\, /, &, \", ?, <, >, and .") }

  # don't allow spaces
  validates_format_of :xml_element_name, :xsi_type, :with => /^[^\s]*$/, :message => lambda { I18n.t('extended_field_model.no_spaces') }

  # TODO: add validation that prevents adding xsi_type without xml_element_name

  # don't allow topic or content base attributes: title, description
  invalid_label_names = TopicType.column_names + ContentType.column_names
  validates_exclusion_of :label, :in => invalid_label_names, :message => lambda { I18n.t('extended_field_model.already_used', :invalid_label_names => invalid_label_names.join(", ")) }

  # TODO: globalize stuff, uncomment later
  # translates :label, :description

  # TODO: might want to reconsider using subselects here
  def self.find_available_fields(type,type_of)
    if type_of == 'TopicType'
      # exclude ancestor's fields as well
      topic_types_to_exclude = type.ancestors + [type]
      find(:all, :readonly => false,
           :conditions => ["id not in (select extended_field_id from topic_type_to_field_mappings where topic_type_id in (?))", topic_types_to_exclude])
    elsif type_of == 'ContentType'
      find(:all, :readonly => false,
           :conditions => ["id not in (select extended_field_id from content_type_to_field_mappings where content_type_id = ?)", type])
    else
      # TODO: this is an error, say something meaningful
    end
  end

  def add_checkbox
    # used by a form of available fields where 0 is always going to be the starting value
    return 0
  end

  alias required_checkbox add_checkbox

  def label_for_params
    self.label.downcase.gsub(/ /, '_')
  end

  def is_a_choice?
    ['autocomplete', 'choice'].include?(ftype)
  end

  def link_choice_values
    dont_link_choice_values.nil? || !dont_link_choice_values
  end
  alias link_choice_values? link_choice_values

  def link_choice_values=(value)
    self.dont_link_choice_values = !value.param_to_obj_equiv
  end

  def is_required?(controller, topic_type_id=nil)
    raise "ERROR: You must specify a topic type id since controller is topics" if controller == 'topics' && topic_type_id.nil?
    if controller == 'topics'
      # we have to check the submitted topic_type or its ancestors
      topic_type = TopicType.find(topic_type_id)
      all_possible_topic_types = topic_type.ancestors + [topic_type]
      ef_mapping = topic_type_to_field_mappings.find_by_topic_type_id(all_possible_topic_types)
    else
      content_type = ContentType.find_by_controller(controller)
      ef_mapping = ContentTypeToFieldMapping.find_by_content_type_id_and_extended_field_id(content_type, self)
    end
    ef_mapping.required?
  end

  # turn pretty urls on or off here
  include FriendlyUrls
  alias :to_param :format_for_friendly_unicode_urls

  protected

    def validate
      errors.add('label', I18n.t('extended_field_model.label_cant_have')) if label && label.strip =~ /^(form|input|script)$/i
    end

end
