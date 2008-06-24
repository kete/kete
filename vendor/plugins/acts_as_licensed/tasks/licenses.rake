namespace :acts_as_licensed do 

  desc "Import New Zealand Creative Commons Licenses from plugin fixtures."
  task :import_nz_cc_licenses => :environment do
    import_attrs(YAML.load(File.open(File.join(RAILS_ROOT, 'vendor/plugins/acts_as_licensed/fixtures/nz_default_creative_commons_licenses.yml'))))
  end
  
  desc "Import Australian Creative Commons Licenses from plugin fixtures."
  task :import_au_cc_licenses => :environment do
    import_attrs(YAML.load(File.open(File.join(RAILS_ROOT, 'vendor/plugins/acts_as_licensed/fixtures/au_default_creative_commons_licenses.yml'))))
  end
  
  def import_attrs(attr_sets)
    attr_sets.each do |attrs|
      # Fixtures are returned as name => { value, .. }. We only need the values.
      attrs = attrs.last
      
      # Only insert licences if they do not already exist, using URL as unique key.
      if !License.find(:first, :conditions => ['url = ?', attrs["url"]])
        begin
          License.create!(attrs)
          p "Inserted license: '#{attrs["name"]}'."
        rescue
          p "Inserting license '#{attrs["name"]} failed: #{$!}."
        end
      else
        p "Skipped '#{attrs["name"]}': License already exists."
      end
    end
  end
  
end
        