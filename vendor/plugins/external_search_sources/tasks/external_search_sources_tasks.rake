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

    desc "Import Kete Horowhenua Images Search Source."
    task :kete_horowhenua_images => :environment do
      plugin_path = File.dirname(__FILE__).gsub('/tasks', '')
      SearchSource.import_from_yaml("#{plugin_path}/fixtures/kete_horowhenua_images.yml")
    end

  end

end
