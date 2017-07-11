require 'oai'
require 'system_setting'
require 'user'

# ruby-oai gem: http://rubydoc.info/gems/oai/0.3.1/frames
# OAI PMH spec: http://www.openarchives.org/OAI/openarchivesprotocol.html

class OaiPmhRepositoryProvider < OAI::Provider::Base
  if SystemSetting.provide_oai_pmh_repository
    repository_name SystemSetting.pretty_site_name
    repository_url '/oai_pmh_repository'
    record_prefix ''
    admin_email SystemSetting.admin_email

    # EOIN: not sure how to get this working yet
    # Since we are not using Zoom we will need to implement a
    # source_model OAI::Provider::ActiveRecordWrapper.new(nil)

    # RABID: original zoom call:
    # source_model OAI::Provider::ZoomDbWrapper.new(ZoomDb.find_by_database_name('public'), :limit => 1000)
  end
end
