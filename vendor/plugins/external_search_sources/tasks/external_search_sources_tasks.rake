namespace :external_search_sources do

  desc "Sync extra files from external_search_sources plugin."
  task :sync do
    plugin_path = File.dirname(__FILE__).gsub('/tasks', '')
    system "rsync -ruv #{plugin_path}/db/migrate db"
    system "rsync -ruv #{plugin_path}/public/images public"
  end

  desc 'Import all Search Source fixture data'
  task :import => ['external_search_sources:import:kete_horowhenua_images']

  namespace :import do

    plugin_path = File.dirname(__FILE__).gsub('/tasks', '')
    Dir["#{plugin_path}/fixtures/*"].each do |fixture|
      name = fixture.split('/').last.split('.').first
      desc "Import #{name.humanize} Search Source."
      task name.to_sym => :environment do
        SearchSource.import_from_yaml(fixture, { :api_key => ENV['API_KEY'] })
      end
    end

  end

end
