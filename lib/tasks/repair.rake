# James - 2008-09-12

# Rake tasks to repair Kete data to ensure integrity

namespace :kete do
  namespace :repair do
    
    # Run all tasks
    task :all => ['kete:repair:fix_topic_versions', 'kete:repair:set_missing_contributors']
    
    desc "Fix invalid topic versions (adds version column value or prunes on a case-by-case basis."
    task :fix_topic_versions => :environment do
      pruned = 0
      fixed = 0
      
      # In some cases the topic_versions table has extra, invalid versions.
      # In this case we are going to find candidates, check their invalidity, and delete them.
      
      # Get candidates
      Topic::Version.find(:all, :conditions => ['version IS NULL']).each do |topic_version|
        
        topic = topic_version.topic
        
        # Check that the topic is valid itself
        next unless topic.version > 0
        
        # Check that the topic has the right number of versions.
        if topic.versions.size > topic.version
        
          # The topic will not have any contributions since is has 
          # no version to be referenced against.
        
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
        
        else
          
          existing_versions = topic.versions.map { |v| v.version }
          
          if !existing_versions.member?(topic.version)
            
            topic_version.update_attribute(:version, topic.version)
            
            print "Fixed missing version for Topic with id = #{topic_version.topic_id} (current version).\n"
            fixed = fixed + 1
            
          else
            
            max = [topic.version, existing_versions.max].max
            
            missing = (1..max).detect { |v| !existing_versions.member?(v) }
            
            topic_version.update_attribute(:version, missing) if missing
            
            print "Fixed missing version for Topic with id = #{topic_version.topic_id} (version #{missing}).\n"
            fixed = fixed + 1
            
          end
        end
            
      end
      
      print "Finished. Removed #{pruned} invalid topic versions.\n"
      print "Finished. Fixed #{fixed} topic versions with missing version attributes.\n"
    end
    
    desc "Set missing contributors on topic versions."
    task :set_missing_contributors => :environment do
      fixed = 0
      
      Topic::Version.find(:all).each do |topic_version|
        
        # Check that this is a valid topic version.
        next if topic_version.version.nil?
        
        # Check that there are not already contributions
        
        sql = <<-SQL
          SELECT COUNT(*) FROM contributions 
            WHERE contributed_item_type = "Topic" 
            AND contributed_item_id = #{topic_version.topic.id} 
            AND version = #{topic_version.version};
        SQL
        
        next unless Contribution.count_by_sql(sql) == 0
        
        Contribution.create(
          :contributed_item => topic_version.topic,
          :version => topic_version.version,
          :contributor_role => topic_version.version == 1 ? "creator" : "contributor",
          :user_id => 1
        )
        
        print "Added contributor for version #{topic_version.version} of Topic with id = #{topic_version.topic.id}.\n"
        fixed = fixed + 1
      end
      
      print "Finished. Added contributor to #{fixed} topic versions.\n"
    end
  end
end
