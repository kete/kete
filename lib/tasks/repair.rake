# James - 2008-09-12

# Rake tasks to repair Kete data to ensure integrity

namespace :kete do
  namespace :repair do
    
    # Run all tasks
    task :all => ['kete:repair:fix_topic_versions', 'kete:repair:set_missing_contributors']
    
    desc "Fix invalid topic versions (adds version column value or prunes on a case-by-case basis."
    task :fix_topic_versions => :environment do
      
      # This task repairs all Topic::Versions where #version is nil. This is a problem because it causes
      # exceptions when visiting history pages on items.
      
      pruned, fixed = 0, 0
      
      # First, find all the candidate versions
      Topic::Version.find(:all, :conditions => ['version IS NULL'], :order => 'id ASC').each do |topic_version|
        
        topic = topic_version.topic
        
        # Skip any problem topics
        next unless topic.version > 0
        
        # Find all existing versions
        existing_versions = topic.versions.map { |v| v.version }.compact
        
        # Find the maximum version
        max = [topic.version, existing_versions.max].compact.max
        
        # Find any versions that are missing from the range of versions we expect to find,
        # given the maximum version we found above..  
        missing = (1..max).detect { |v| !existing_versions.member?(v) }
        
        if missing
          
          # The current topic_version has no version attribute, and there is a version missing from the set.
          # Therefore, the current version is likely the missing one.
          
          # Set the version on this topic_version to the missing one..
          
          topic_version.update_attributes!(
            :version => missing,
            :version_comment => topic_version.version_comment.to_s + " NOTE: Version number fixed automatically."
          )
          
          print "Fixed missing version for Topic with id = #{topic_version.topic_id} (version #{missing}).\n"
          fixed = fixed + 1
          
        elsif topic.versions.size > max
          
          # There are more versions than we expected, and there are no missing version records.
          # So, this version must be additional to requirements. We need to remove the current topic_version.
          
          # Clean up any flags/tags
          topic_version.flags.clear
          topic_version.tags.clear

          # Check the associations have been cleared
          topic_version.reload

          raise "Could not clear associations" if \
            topic_version.flags.size > 0 || topic_version.tags.size > 0

          # Prune if we're still here..
          topic_version.destroy

          print "Deleted invalid version for Topic with id = #{topic_version.topic_id}.\n"
          pruned = pruned + 1
                      
        end
            
      end
      
      print "Finished. Removed #{pruned} invalid topic versions.\n"
      print "Finished. Fixed #{fixed} topic versions with missing version attributes.\n"
    end
    
    desc "Set missing contributors on topic versions."
    task :set_missing_contributors => :environment do
      fixed = 0
      
      # This rake task runs through all topic_versions and adds a contributor/creator to any
      # which are missing them.
      
      # This is done because a missing contributor results in exceptions being raised on the
      # topic history pages.
      
      Topic::Version.find(:all).each do |topic_version|
        
        # Check that this is a valid topic version.
        next if topic_version.version.nil?
        
        # Identify any existing contributors for the current topic_version and skip to the next
        # if existing contributors are present.
        
        sql = <<-SQL
          SELECT COUNT(*) FROM contributions 
            WHERE contributed_item_type = "Topic" 
            AND contributed_item_id = #{topic_version.topic.id} 
            AND version = #{topic_version.version};
        SQL
        
        next unless Contribution.count_by_sql(sql) == 0
        
        # Add the admin user as the contributor and add a note to the version comment.
        
        Contribution.create(
          :contributed_item => topic_version.topic,
          :version => topic_version.version,
          :contributor_role => topic_version.version == 1 ? "creator" : "contributor",
          :user_id => 1
        )
        
        topic_version.update_attribute(:version_comment, topic_version.version_comment.to_s + " NOTE: Contributor added automatically. Actual contributor unknown.")
        
        print "Added contributor for version #{topic_version.version} of Topic with id = #{topic_version.topic.id}.\n"
        fixed = fixed + 1
      end
      
      print "Finished. Added contributor to #{fixed} topic versions.\n"
    end
  end
end
