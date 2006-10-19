class TopicTypeToFieldMapping < ActiveRecord::Base
  belongs_to :topic_type
  belongs_to :topic_type_field
  belongs_to :form_field, :class_name => "TopicTypeField", :foreign_key => "topic_type_field_id"
  belongs_to :required_form_field, :class_name => "TopicTypeField", :foreign_key => "topic_type_field_id"
  acts_as_list :scope => :topic_type_id
  piggy_back :topic_type_field_name,
      :from => :topic_type_field, :attributes => [:name]
  # position should never be null, but it's not specified directly at creation at this point, so not validating here
  # there is a test for it though

end
