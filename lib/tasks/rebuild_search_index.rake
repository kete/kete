namespace :kete do
  desc 'Rebuild the pg_search multisearch index'
  task rebuild_search_index: :environment do

    puts 'Starting search index rebuild:'
    searchable_models = [Topic, AudioRecording, StillImage, Document, Comment, WebLink, Video]

    searchable_models.each do |model|
      puts "  rebuilding #{model.to_s}"
      PgSearch::Multisearch.rebuild(model)
    end

    puts 'Completed search index rebuild'
  end
end
