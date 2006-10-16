class TopicTypeToFieldMapping < ActiveRecord::Base
  belongs_to :topic_type
  belongs_to :topic_type_field
  belongs_to :form_field, :class_name => "TopicTypeField", :foreign_key => "topic_type_field_id"
  belongs_to :required_form_field, :class_name => "TopicTypeField", :foreign_key => "topic_type_field_id"
  acts_as_list :scope => :topic_type_id
end
