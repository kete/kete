# = ProfileMapping
#
# How we declare whether a model has a profile. See Profile.
#
# Add a new profile/basket mapping by using the following:
#
# basket.profiles << Profile.find(id)
#
class ProfileMapping < ActiveRecord::Base
  belongs_to :profile
  belongs_to :profilable, polymorphic: true

  validates_presence_of :profile_id, :profilable_type, :profilable_id
end
