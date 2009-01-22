class ContentTypeToFieldMapping < ActiveRecord::Base
  belongs_to :content_type
  belongs_to :extended_field
  belongs_to :form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
  belongs_to :required_form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
  acts_as_list :scope => :content_type_id
  piggy_back :extended_field_label_xml_element_name_xsi_type_multiple_and_description,
      :from => :extended_field, :attributes => [:label, :xml_element_name, :xsi_type, :multiple, :description]

  # James: Leaving this out for now. See notes below (line 21) for details.
  # this creates reading and writing methods for an extendef field when it is mapped to a content_type
  # after_create :define_extended_field_accessors
  # after_destroy :undefine_extended_field_accessors

  def self.add_as_to(is_required, content_type, field)
      with_scope(:create => { :required => is_required}) { content_type.concat field }
  end

  private
  
    # James: Leaving this out initially as I am not convinced it is necessary given the cost of maintaining the code.
    # In my brief research I think we'll need to be hitting method_missing quite often to notice a significant performance difference if
    # any as the performance deficit is only related to the extra search Ruby needs to do when locating the method - method_missing
    # is the 'last resort' kind of place to search.

    # these dynamic definitions get cleared at app restart
    # so we have a method_missing on the content type or topic model
    # that will define them at the time they are first called
    # call the method on the model that will define =, +=, and reader methods for the mapped extended field
    # def define_extended_field_accessors
    #   content_type_class_name = content_type.class_name
    #   logger.debug("what is define content_type_class: " + content_type_class_name.inspect)
    #   Module.class_eval(content_type_class_name).send(:define_methods_for, extended_field)
    # end

    # call the method on the model that will undefine =, +=, and reader methods for the mapped extended field
    # def undefine_extended_field_accessors
    #   content_type_class_name = content_type.class_name
    #   logger.debug("what is undefine content_type_class_name: " + content_type_class_name.inspect)
    #   Module.class_eval(content_type_class_name).send(:undefine_methods_for, extended_field)
    # end
  
end
