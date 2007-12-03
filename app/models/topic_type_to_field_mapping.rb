class TopicTypeToFieldMapping < ActiveRecord::Base
  belongs_to :topic_type
  belongs_to :extended_field
  belongs_to :form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
  belongs_to :required_form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
  acts_as_list :scope => :topic_type_id
  piggy_back :extended_field_label_xml_element_name_xsi_type_multiple_and_description,
      :from => :extended_field, :attributes => [:label, :xml_element_name, :xsi_type, :multiple, :description]
  # position should never be null, but it's not specified directly at creation at this point, so not validating here
  # there is a test for it though

  # TODO: add validation that prevents adding any fields to the generic topic_type of id 1

  def self.add_as_to(is_required, topic_type, field)
      with_scope(:create => { :required => is_required}) { topic_type.concat field }
  end
end
