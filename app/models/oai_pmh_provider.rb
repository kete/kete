require 'oai'

# EOIN: why is the if wrapping the class declaration? Is there a reason that it shouldn't be inside?
if SystemSetting.is_configured? && defined?(SystemSetting.provide_oai_pmh_repository?) && SystemSetting.provide_oai_pmh_repository?
  class OaiPmhRepositoryProvider < OAI::Provider::Base
    repository_name SystemSetting.pretty_site_name
    repository_url "#{SystemSetting.full_site_url}oai_pmh_repository"
    record_prefix '' # this may need to be ZoomDb.zoom_id_stub.chop
    admin_email User.find(1).email
    source_model OAI::Provider::ZoomDbWrapper.new(ZoomDb.find_by_database_name('public'), :limit => 1000)
  end
else
    class OaiPmhRepositoryProvider < OAI::Provider::Base
    end
end
