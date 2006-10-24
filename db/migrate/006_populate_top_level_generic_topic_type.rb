class PopulateTopLevelGenericTopicType < ActiveRecord::Migration
  def self.up
    TopicType.create(:name => 'Topic',
                     :description =>
                     %{<p>The top most topic type from which all other topic types inherit their attributes.  This topic type can't be altered by adding new topic type form fields.</p>})
  end

  def self.down
    TopicType.delete_all
  end
end
