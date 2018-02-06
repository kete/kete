# frozen_string_literal: true

require 'test_helper'

class ProfileMappingTest < ActiveSupport::TestCase
  should belong_to(:profile)
  should belong_to(:profilable)
  should validate_presence_of(:profile_id)
  should validate_presence_of(:profilable_id)
  should validate_presence_of(:profilable_type)
end
