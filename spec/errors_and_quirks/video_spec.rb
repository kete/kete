require 'spec_helper'

describe Video do
  describe "error:" do
    it "creates two versions when first saved" do
      # ROB: ERROR
      # The #revert_to_latest_unflagged_version_or_create_blank_version()
      # method in lib/flagging.rb causes a quirk in the code.
      # If there aren't any video_versions rows in the DB, an update_attributes!
      # is run creating an new row in the video_versions table with null values.

      video1 = FactoryGirl.create(:versionable_video)
      expect(video1.versions.size).to eq(2)
      # Oops there should be 1 version

      video1.update_attribute(:title, "changed title")
      expect(video1.versions.size).to eq(3)
      # It seems to work fine after that.

      video2 = FactoryGirl.create(:versionable_video)
      expect(video2.versions.size).to eq(2)
      # but a new video gets the same problem
    end
  end
end 

