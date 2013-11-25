require 'spec_helper'

describe Video do
  let(:video) { }
  # let(:video) { Video.new }

  it "does not blow up when you initialize it" do
    video
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


      it "explore: save a video" do
        video_content_type = ContentType.create!(class_name: "Video",
                                 description: "foo",
                                 controller: "video",
                                 humanized_plural: "Videos",
                                 humanized: "Video")
        expect(video_content_type).to be_valid

        # this must exist in the DB before you can create a user
        user_content_type = ContentType.create!(class_name: "User",
                                 description: "foo",
                                 controller: "user",
                                 humanized_plural: "Users",
                                 humanized: "User")
        expect(user_content_type).to be_valid


        valid_user_attributes = { 
          :login => 'quire',
          :email => 'quire@example.com',
          :password => 'quire',
          :password_confirmation => 'quire',
          :agree_to_terms => '1',
          :security_code => 'test',
          :security_code_confirmation => 'test',
          :locale => 'en' 
        }

        user = User.create!(valid_user_attributes)
        expect(user).to be_valid


        basket = Basket.create!( name: 'Site',
                                 urlified_name: 'site',
                                 index_page_basket_search: "0",
                                 index_page_archives_as: 'by type',
                                 private_default: false,
                                 file_private_default: false,
                                 allow_non_member_comments: true,
                                 show_privacy_controls: false,
                                 status: 'approved',
                                 creator_id: 1)

        expect(basket).to be_valid


        video_attrs = {
          title:         "foo",
          content_type:  "video/mpeg",
          size:          123,
          filename:      "foo.mpg"
        }

        vid2 = Video.new(video_attrs)
        expect(vid2).to be_valid

        # video needs to have a basket before it will save
        # TODO: this implies that basket should be checked by a validation ???
        vid2.basket = basket

        expect { vid2.save! }.to_not raise_error
        
        binding.pry

        # ROB: ERROR
        # There is a quirk in the code in lib/flagging.rb
        # (#revert_to_latest_unflagged_version_or_create_blank_version method)
        # where if there is not already a version in the DB, it runs an
        # update_attributes!. The result of this that there is an extra row
        # created in the video_versions table that has null values.
        expect(vid2.versions.size).to eq(2)
      end
    end
  end
end 
