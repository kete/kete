# frozen_string_literal: true

class ContentTypeToFieldMapping < ActiveRecord::Base
  include FieldMappings

  # James: Leaving this out for now. See notes below (line 11) for details.
  # this creates reading and writing methods for an extendef field when it is mapped to a content_type
  # after_create :define_extended_field_accessors
  # after_destroy :undefine_extended_field_accessors

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
