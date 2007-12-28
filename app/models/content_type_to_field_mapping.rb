class ContentTypeToFieldMapping < ActiveRecord::Base
  belongs_to :content_type
  belongs_to :extended_field
  belongs_to :form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
  belongs_to :required_form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
  acts_as_list :scope => :content_type_id
  piggy_back :extended_field_label_xml_element_name_xsi_type_multiple_and_description,
      :from => :extended_field, :attributes => [:label, :xml_element_name, :xsi_type, :multiple, :description]

  def self.add_as_to(is_required, content_type, field)
      with_scope(:create => { :required => is_required}) { content_type.concat field }
  end
end
