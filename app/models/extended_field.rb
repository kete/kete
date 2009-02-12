class ExtendedField < ActiveRecord::Base
  include ExtendedFieldsHelpers

  # Choices/enumerations
  has_many :choice_mappings, :as => :field
  has_many :choices, :through => :choice_mappings

  # find an extended field based on label_for_params
  # TODO: not sure this is DB agnostic enough to work with PostgreSQL
  named_scope :from_label_for_params, lambda { |label_for_params| { :conditions => ['UPPER(label) = ?', label_for_params.upcase.gsub('_', ' ')] } }

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
  validates_format_of :label, :with => /^[^\'\":<>\&,\/\\\?\.]*$/, :message => ": \', \\, /, &, \", ?, <, >, and . characters aren't allowed"

  # don't allow spaces
  validates_format_of :xml_element_name, :xsi_type, :with => /^[^\s]*$/, :message => ": spaces aren't allowed"

  # TODO: add validation that prevents adding xsi_type without xml_element_name

  # don't allow topic or content base attributes: title, description
  invalid_label_names = TopicType.column_names + ContentType.column_names
  validates_exclusion_of :label, :in => invalid_label_names, :message => ": labels of " + invalid_label_names.join(", ") + " aren't allowed because they already used be default"

  # TODO: globalize stuff, uncomment later
  # translates :label, :description

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

  def is_required?(controller, topic_type_id=nil)
    raise "ERROR: You must specify a topic type id since controller is topics" if controller == 'topics' && topic_type_id.nil?
    if controller == 'topics'
      ef_mapping = TopicTypeToFieldMapping.find_by_topic_type_id_and_extended_field_id(topic_type_id, self)
    else
      content_type = ContentType.find_by_controller(controller)
      ef_mapping = ContentTypeToFieldMapping.find_by_content_type_id_and_extended_field_id(content_type, self)
    end
    ef_mapping.required?
  end

  protected

    def validate
      errors.add('label', "cannot contain Form, Script, or Input because they are reserved starting words") if label =~ /^(form|input|script)(.*)$/i
    end

end
