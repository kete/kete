class TopicTypeToFieldMapping < ActiveRecord::Base
  include FieldMappings

  # position should never be null, but it's not specified directly at creation at this point, so not validating here
  # there is a test for it though

  # TODO: add validation that prevents adding any fields to the generic topic_type of id 1
end
