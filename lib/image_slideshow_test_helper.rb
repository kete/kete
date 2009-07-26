module ImageSlideshowTestHelper
  unless included_modules.include? ImageSlideshowTestHelper
    def self.included(base)
      base.class_eval do

        context "The topic related image slideshow" do

          context "when several images are related to a topic, the slideshow" do

            setup do
              @topic = Topic.create(:title => 'Parent Topic', :topic_type_id => TopicType.first, :basket_id => Basket.first)
              @topic.creator = User.first
              create_new_image_relation_to(@topic, :title => 'Child Image 1')
              create_new_image_relation_to(@topic, :title => 'Child Image 2')
              create_new_image_relation_to(@topic, :title => 'Child Image 3')
            end

            should "be populated in the session on selected image visit" do
              selected_image_params = { :urlified_name => @topic.basket.urlified_name, :topic_id => @topic.id }

              # initial population and correct values (clicking play button)
              get :selected_image, selected_image_params
              check_slideshow_values_correct :current => 0

              # simulate auto slideshow progression (used by slideshow via JS)
              get :selected_image, selected_image_params
              check_slideshow_values_correct :current => 1
              get :selected_image, selected_image_params
              check_slideshow_values_correct :current => false
              # check it loops back to the first one
              get :selected_image, selected_image_params
              check_slideshow_values_correct :current => 0

              # test next button
              session['image_slideshow'] = nil
              get :selected_image, selected_image_params
              get :selected_image, selected_image_params.merge(:id => session['image_slideshow']['results'][1].split('/').last.to_i)
              check_slideshow_values_correct :current => 1

              # test previous button
              session['image_slideshow'] = nil
              get :selected_image, selected_image_params
              get :selected_image, selected_image_params.merge(:id => session['image_slideshow']['results'][2].split('/').last.to_i)
              check_slideshow_values_correct :current => 1
            end

          end

        end

        private

        def create_new_image_relation_to(topic, options = {})
          @@documentdata ||= fixture_file_upload('/files/white.jpg', 'image/jpeg')

          new_still_image = StillImage.create({ :title => 'Child Image', :basket_id => Basket.first }.merge(options))
          new_still_image.creator = User.first
          new_image_file  = ImageFile.create(:uploaded_data => @@documentdata, :still_image_id => new_still_image.id)
          ContentItemRelation.new_relation_to_topic(@topic, new_still_image)

          new_still_image
        end

        def check_slideshow_values_correct(options = {})
          assert_equal (options[:total] || 3), session['image_slideshow']['results'].size
          assert_equal (options[:total] || 3), session['image_slideshow']['total']
          assert_equal (options[:topic_id] || @topic.id), session['image_slideshow']['key']['slideshow_topic_id'] if options[:topic_id]
          # we do not store a last requested if this is the last image in the slideshow
          if options[:current]
            assert_equal session['image_slideshow']['results'][options[:current]], session['image_slideshow']['last_requested']
          else
            assert_equal nil, session['image_slideshow']['last_requested']
          end
        end

      end
    end
  end
end
