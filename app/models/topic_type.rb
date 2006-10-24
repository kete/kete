require 'ajax_scaffold'

class TopicType < ActiveRecord::Base
  # dependent topics should be what if a topic_type is destroyed?
  has_many :topics
  has_many :topic_type_to_field_mappings, :dependent => :destroy, :order => 'position'
  # Walter McGinnis (walter@katipo.co.nz), 2006-10-05
  # these association extension maybe able to be cleaned up with modules or something in rails proper down the line
  # code based on work by hasmanythrough.com
  # you have to do the elimination of dupes through the sql
  # otherwise, rails will reorder by topic_type_to_field_mapping.id after the sql has bee run
  has_many :form_fields, :through => :topic_type_to_field_mappings, :source => :topic_type_field, :select => "distinct topic_type_to_field_mappings.position, topic_type_fields.*", :order => 'position' do
    def <<(topic_type_field)
      TopicTypeToFieldMapping.with_scope(:create => { :required => "false"}) { self.concat topic_type_field }
    end
  end
  has_many :required_form_fields, :through => :topic_type_to_field_mappings, :source => :required_form_field, :select => "distinct topic_type_to_field_mappings.position, topic_type_fields.*", :conditions => "topic_type_to_field_mappings.required = 'true'", :order => 'position', :uniq => true do
    def <<(required_form_field)
      TopicTypeToFieldMapping.with_scope(:create => { :required => "true"}) { self.concat required_form_field }
    end
  end
  validates_presence_of :name, :description
  validates_uniqueness_of :name
  # globalize stuff, uncomment later
  # translates :name, :description

  # we have a generic topic_type of Topic from which all types inherit their attributes
  # since these default fields reflect the state of the Topic model
  def available_fields
    @available_fields = TopicTypeField.find_available_fields(self)
  end
end
