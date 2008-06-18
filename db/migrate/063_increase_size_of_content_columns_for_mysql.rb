class IncreaseSizeOfContentColumnsForMysql < ActiveRecord::Migration
  def self.up
    
    # TODO. Add a warning here?
    
    # Only run this migration for MySQL backed Kete.
    if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::MysqlAdapter)

      # List of tables and columns to be changed to MEDIUMTEXT
      tables_and_columns = {
        "audio_recordings"          => ["description", "extended_content", "private_version_serialized"],
        "audio_recording_versions"  => ["description", "extended_content"],
        "baskets"                   => ["extended_content", "index_page_extra_side_bar_html"],
        "comments"                  => ["description", "extended_content"],
        "comment_versions"          => ["description", "extended_content"],
        "documents"                 => ["description", "extended_content", "private_version_serialized"],
        "document_versions"         => ["description", "extended_content"],
        "still_images"              => ["description", "extended_content", "private_version_serialized"],
        "still_image_versions"      => ["description", "extended_content"],
        "topics"                    => ["description", "extended_content", "private_version_serialized"],
        "topic_versions"            => ["description", "extended_content"],
        "users"                     => ["extended_content"],
        "videos"                    => ["description", "extended_content", "private_version_serialized"],
        "video_versions"            => ["description", "extended_content"],
        "web_links"                 => ["description", "extended_content", "private_version_serialized"],
        "web_link_versions"         => ["description", "extended_content"]
      }
      
      tables_and_columns.each do |table, columns|
        columns.each do |column|
          execute "ALTER TABLE #{table} CHANGE COLUMN #{column} #{column} MEDIUMTEXT"
        end
      end
      
    else
      print "Skipping migration. MySQL specific."
    end
  end

  def self.down
    print "\n/!\\ Skipping down migration. MySQL MEDIUMTEXT -> TEXT migration could be dangerous. /!\\ \n\n"
    
    # Only run this migration for MySQL backed Kete.
    # if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
    # 
    #   # List of tables and columns to be changed to MEDIUMTEXT
    #   tables_and_columns = {
    #     "audio_recordings"          => ["description", "extended_content", "private_version_serialized"],
    #     "audio_recording_versions"  => ["description", "extended_content"],
    #     "baskets"                   => ["extended_content", "index_page_extra_side_bar_html"],
    #     "comments"                  => ["description", "extended_content"],
    #     "comment_versions"          => ["description", "extended_content"],
    #     "documents"                 => ["description", "extended_content", "private_version_serialized"],
    #     "document_versions"         => ["description", "extended_content"],
    #     "still_images"              => ["description", "extended_content", "private_version_serialized"],
    #     "still_image_versions"      => ["description", "extended_content"],
    #     "topics"                    => ["description", "extended_content", "private_version_serialized"],
    #     "topic_versions"            => ["description", "extended_content"],
    #     "users"                     => ["extended_content"],
    #     "videos"                    => ["description", "extended_content", "private_version_serialized"],
    #     "video_versions"            => ["description", "extended_content"],
    #     "web_links"                 => ["description", "extended_content", "private_version_serialized"],
    #     "web_link_versions"         => ["description", "extended_content"]
    #   }
    #   
    #   tables_and_columns.each do |table, columns|
    #     columns.each do |column|
    #       execute "ALTER TABLE #{table} CHANGE COLUMN #{column} #{column} TEXT"
    #     end
    #   end
    #   
    # end
  end
end
