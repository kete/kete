class ExtendedField < ActiveRecord::Base
  include ExtendedFieldsHelpers

  has_many :topic_type_to_field_mappings, :dependent => :destroy
  # if we ever use this association, we'll want to add a test for it
  has_many :topic_type_forms, :through => :topic_type_to_field_mappings, :source => :topic_type, :order => 'position'

  has_many :content_type_to_field_mappings, :dependent => :destroy
  # if we ever use this association, we'll want to add a test for it
  has_many :content_type_forms, :through => :content_type_to_field_mappings, :source => :content_type, :order => 'position'

  validates_presence_of :label
  validates_uniqueness_of :label

  # don't allow special characters in label that will break our xml
  validates_format_of :label, :with => /^[^\'\"<>\&,\/\\\?]*$/, :message => ": \', \\, /, &, \", ?, <, and > characters aren't allowed"

  # don't allow spaces
  validates_format_of :xml_element_name, :xsi_type, :with => /^[^\s]*$/, :message => ": spaces aren't allowed"

  # TODO: add validation that prevents adding xsi_type without xml_element_name

  # TODO: add validation that prevents the generic topic fields from being re-added

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

end
