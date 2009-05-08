namespace :acts_as_licensed do

  desc "DEPRECATED: Please use acts_as_licensed:import:nz_cc_licenses - Import New Zealand Creative Commons Licenses from plugin fixtures. "
  task :import_nz_cc_licenses => :environment do
    License.import_from_yaml('nz_default_creative_commons_licenses.yml')
  end

  desc "DEPRECATED: Please use acts_as_licensed:import:au_cc_licenses - Import Australian Creative Commons Licenses from plugin fixtures."
  task :import_au_cc_licenses => :environment do
    License.import_from_yaml('au_default_creative_commons_licenses.yml')
  end

  namespace :import do

    desc "Import New Zealand Creative Commons Licenses from plugin fixtures."
    task :nz_cc_licenses => :environment do
      License.import_from_yaml('nz_default_creative_commons_licenses.yml')
    end

    desc "Import Australian Creative Commons Licenses from plugin fixtures."
    task :au_cc_licenses => :environment do
      License.import_from_yaml('au_default_creative_commons_licenses.yml')
    end

  end

end
