# frozen_string_literal: true

class TopicTypeToFieldMapping < ActiveRecord::Base
  include FieldMappings

  # position should never be null, but it's not specified directly at creation at this point, so not validating here
  # there is a test for it though

  # TODO: add validation that prevents adding any fields to the generic topic_type of id 1

  # def extended_field_label ;            extended_field.label ; end
  # def extended_field_multiple ;         extended_field.multiple ; end
  # def extended_field_xml_element_name ; extended_field.xml_element_name ; end
  # def extended_field_xsi_type ;         extended_field.xsi_type ; end
end
