class TopicTypeField < ActiveRecord::Base
  has_many :topic_type_to_field_mappings, :dependent => :destroy
  # if we ever use this association, we'll want to add a test for it
  has_many :topic_type_forms, :through => :topic_type_to_field_mappings, :source => :topic_type, :order => 'position'
  validates_presence_of :label
  validates_uniqueness_of :label
  # don't allow spaces
  validates_format_of :xml_element_name , :with => /[^\S]/, :message => "Spaces aren't allowed in XML elment names."
  # TODO: add validation that prevents the generic topic fields from being re-added
  # globalize stuff, uncomment later
  # translates :label, :description
  def self.find_available_fields(topic_type)
    find(:all, :readonly => false,
         :conditions => ["id not in (select topic_type_field_id from topic_type_to_field_mappings where topic_type_id = ?)", topic_type.id])
  end
  # TODO: make this DRY!
  def add_checkbox
    # used by a form of available fields where 0 is always going to be the starting value
    return 0
  end
  def required_checkbox
    # used by a form of available fields where 0 is always going to be the starting value
    return 0
  end
end
