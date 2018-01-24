module ImageSlideshowTestHelper
  unless included_modules.include? ImageSlideshowTestHelper
    def self.included(base)
      base.class_eval do
        if base.name == 'IndexPageControllerTest'
          context 'The index page' do
            setup do
              3.times { |i| create_new_still_image_with(title: "site basket image #{i + 1}") }

              @different_basket = create_new_basket({ name: 'different basket' })

              3.times do |i|
                create_new_still_image_with(title: "different basket image #{i + 1}",
                                            basket_id: @different_basket.id)
              end
            end

            should 'have slideshow be populated in the session on selected image visit when it is for the site basket with all images in both site and other basket' do
              run_through_selected_images(selected_image_params: {
                                            urlified_name: Basket.first.urlified_name
                                          },
                                          total: 6)
            end

            should 'have slideshow be populated in the session on selected image visit when it is not for the site basket, but another basket limited to just the basket images' do
              run_through_selected_images(selected_image_params: {
                                            urlified_name: @different_basket.urlified_name,
                                            controller: 'index_page'
                                          })
            end
          end
        else

          context 'The topic related image slideshow' do
            context 'when several images are related to a topic' do
              setup do
                @non_site_basket_1 = create_new_basket({ name: 'basket 1' })

                @topic = Topic.create(title: 'Parent Topic', topic_type_id: TopicType.first, basket_id: @non_site_basket_1.id)
                @topic.creator = User.first
              end

              context 'and the images are in the same basket' do
                setup do
                  3.times { |i| create_new_image_relation_to(@topic, title: "Child Image #{i + 1}") }
                end

                should 'have slideshow be populated in the session on selected image visit' do
                  run_through_selected_images
                end
              end

              context 'and the images are in a different basket from topic' do
                setup do
                  3.times do |i|
                    create_new_image_relation_to(@topic,
                                                 basket_id: create_new_basket({ name: "basket #{i + 1}" }).id,
                                                 title: "Child Image in Another Basket #{i + 1}")
                  end
                end

                should 'have slideshow be populated in the session on selected image visit' do
                  run_through_selected_images
                end
              end
            end
          end
        end

        private

        def run_through_selected_images(options = {})
          options[:current] = options[:current].blank? ? 1 : options[:current].blank?
          selected_image_params = options.delete(:selected_image_params)

          if @topic
            options[:topic_id] = @topic.id
            selected_image_params = { urlified_name: @topic.basket.urlified_name,
                                      topic_id: @topic.id }
          end

          # initial population and correct values (clicking play button)
          get :selected_image, selected_image_params
          check_slideshow_values_correct(options.merge({ current: 0 }))

          unless options[:total]
            # simulate auto slideshow progression (used by slideshow via JS)
            get :selected_image, selected_image_params
            check_slideshow_values_correct(options)

            get :selected_image, selected_image_params
            check_slideshow_values_correct(options.merge({ current: nil }))
            # check it loops back to the first one
            get :selected_image, selected_image_params
            check_slideshow_values_correct(options.merge({ current: 0 }))
          end

          # test next button
          session['image_slideshow'] = nil
          get :selected_image, selected_image_params
          get :selected_image, selected_image_params.merge(id: session['image_slideshow']['results'][1].split('/').last.to_i)
          check_slideshow_values_correct(options)

          # test previous button
          session['image_slideshow'] = nil
          get :selected_image, selected_image_params
          get :selected_image, selected_image_params.merge(id: session['image_slideshow']['results'][2].split('/').last.to_i)
          check_slideshow_values_correct(options)
        end

        def create_new_still_image_with(options = {})
          @@documentdata ||= fixture_file_upload('/files/white.jpg', 'image/jpeg')

          new_still_image = StillImage.create({ title: 'Child Image', basket_id: Basket.first }.merge(options))
          new_still_image.creator = User.first
          new_image_file = ImageFile.create(uploaded_data: @@documentdata, still_image_id: new_still_image.id)
          new_still_image
        end

        def create_new_image_relation_to(topic, options = {})
          new_still_image = create_new_still_image_with(options)
          ContentItemRelation.new_relation_to_topic(@topic, new_still_image)
          new_still_image
        end

        def check_slideshow_values_correct(options = {})
          assert_equal (options[:total] || 3), session['image_slideshow']['results'].size
          assert_equal (options[:total] || 3), session['image_slideshow']['total']
          assert_equal (options[:topic_id] || @topic.id), session['image_slideshow']['key']['slideshow_topic_id'] if options[:topic_id]
          # we do not store a last requested if this is the last image in the slideshow
          unless options[:current].blank?
            assert_equal session['image_slideshow']['results'][options[:current]], session['image_slideshow']['last_requested']
          else
            assert_equal nil, session['image_slideshow']['last_requested']
          end
        end
      end
    end
  end
end
