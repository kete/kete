require 'oai'
require 'system_setting'
require 'user'

class OaiPmhRepositoryProvider < OAI::Provider::Base
  if SystemSetting.is_configured?  && SystemSetting.provide_oai_pmh_repository
    repository_name SystemSetting.pretty_site_name
    repository_url "/oai_pmh_repository"
    record_prefix '' # this may need to be ZoomDb.zoom_id_stub.chop
    admin_email SystemSetting.admin_email

    # EOIN: not sure how to get this working yet
    # source_model OAI::Provider::ZoomDbWrapper.new(ZoomDb.find_by_database_name('public'), :limit => 1000)
  end
end
