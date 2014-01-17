require 'spec_helper'

describe Video do
  let(:video) { Video.new }

  it "does not blow up when you initialize it" do
    video
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validateable_video) ).to be_valid

    # ROB:  Not saveable because of basket (see note in factory).
    expect { FactoryGirl.create(:validateable_video) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_video) ).to be_a(Video)
  end

  it "creates two versions when first save (ERROR)" do
    # ROB: ERROR
    # The #revert_to_latest_unflagged_version_or_create_blank_version()
    # method in lib/flagging.rb causes a quirk in the code.
    # If there aren't any video_versions rows in the DB, an update_attributes!
    # is run creating an new row in the video_versions table with null values.

    video1 = FactoryGirl.create(:saveable_video)
    expect(video1.versions.size).to eq(2)
    # Oops there should be 1 version

    video1.update_attribute(:title, "changed title")
    expect(video1.versions.size).to eq(3)
    # It seems to work fine after that.

    video2 = FactoryGirl.create(:saveable_video)
    expect(video2.versions.size).to eq(2)
    # but a new video gets the same problem
  end

  describe "item privacy" do
    describe "(versioned overload) how it interacts with versioning" do
      describe "instance methods (added to instance of this model class" do
        it "public methods" do
          expect(video).to respond_to(:private_version!)
          expect(video).to respond_to(:public_version!)
          expect(video).to respond_to(:has_public_version?)
          expect(video).to respond_to(:has_private_version?)
          expect(video).to respond_to(:latest_version_is_private?)
          expect(video).to respond_to(:is_private?)
          expect(video).to respond_to(:private_version)
          expect(video).to respond_to(:save_without_saving_private!)
        end
      end

      describe "instance methods (added to instance of this model class" do
        it "class methods" do
          expect(Video).to respond_to(:without_saving_private)
        end
      end
    end
  end
end 
