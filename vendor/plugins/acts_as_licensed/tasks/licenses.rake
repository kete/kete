namespace :acts_as_licensed do 

  desc "Import New Zealand Creative Commons Licenses from plugin fixtures."
  task :import_nz_cc_licenses => :environment do
    License.import_from_yaml('nz_default_creative_commons_licenses.yml')
  end
  
  desc "Import Australian Creative Commons Licenses from plugin fixtures."
  task :import_au_cc_licenses => :environment do
    License.import_from_yaml('au_default_creative_commons_licenses.yml')
  end
  
end
        