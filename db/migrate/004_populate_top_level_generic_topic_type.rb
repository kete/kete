class PopulateTopLevelGenericTopicType < ActiveRecord::Migration
  def self.up
    TopicType.create(
      name: 'Topic',
      description:                      %(The top most topic type from which all other topic types inherit their attributes.  This topic type can't be altered by adding new topic type form fields.)
    )
  end

  def self.down
    TopicTypeToFieldMapping.delete_all
    TopicType.delete_all
  end
end
