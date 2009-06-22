namespace :external_search_sources do
  desc "Sync extra files from external_search_sources plugin."
  task :sync do
    plugin_path = File.dirname(__FILE__).gsub('/tasks', '')
    system "rsync -ruv #{plugin_path}/db/migrate db"
    system "rsync -ruv #{plugin_path}/public/images public"
  end
end
