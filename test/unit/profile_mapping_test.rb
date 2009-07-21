require 'test_helper'

class ProfileMappingTest < ActiveSupport::TestCase
  should_belong_to :profile
  should_belong_to :profilable
  should_validate_presence_of :profile_id, :profilable_id, :profilable_type
end
