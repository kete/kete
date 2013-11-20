require 'spec_helper'

describe Video do
  let(:video) { Video.new }

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

      it "works" do
        video_content_type = ContentType.create!(class_name: "Video",
                                 description: "foo",
                                 controller: "video",
                                 humanized_plural: "Videos",
                                 humanized: "Video")
        expect(video_content_type).to be_valid

        user_content_type = ContentType.create!(class_name: "User",
                                 description: "foo",
                                 controller: "user",
                                 humanized_plural: "Users",
                                 humanized: "User")
        expect(user_content_type).to be_valid

        user = User.create!(login: 'admin',
                            email: 'admin@changeme.com',
                            salt: '7e3041ebc2fc05a40c60028e2c4901a81035d3cd',
                            crypted_password: '00742970dc9e6319f8019fd54864d3ea740f04b1', # test
                            activation_code: 'admincode',
                            activated_at: Time.now.utc.to_s,
                            resolved_name: 'admin',
                            locale: 'en')
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

        video.title = "foo"
        video.content_type = "video/mpeg"
        video.size = 123
        video.filename = "foo.mpg"
        expect(video).to be_valid

        video.save!
      end
    end
  end
end 
