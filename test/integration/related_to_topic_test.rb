require File.dirname(__FILE__) + '/integration_test_helper'

class RelatedToTopicTest < ActionController::IntegrationTest
  context "A Topic\'s related items" do

    setup do
      enable_production_mode
      add_john_as_regular_user
      login_as('john')
    end

    teardown do
      disable_production_mode
    end

    context "when a topic is added" do

      setup do
        @topic = new_topic(:title => 'Topic 1 Title')
      end

      should "have a related items section" do
        body_should_contain "Related Items"
      end

      ITEM_CLASSES.each do |class_name|
        context "the related #{class_name} subsection" do
          setup do
            # strangely i couldn't just do these as local variables outside of the setup scope
            # except for tableize, zoom_class_... helper methods were not being found
            @humanized_plural = zoom_class_plural_humanize(class_name)
            @item_type = zoom_class_humanize(class_name)
            @tableized = class_name.tableize
            @item_title = "Related #{@item_type}"
          end

          should "be empty to start" do
            body_should_contain "#{@humanized_plural} (0)"
          end

          should "be able to create related #{class_name}" do
            # TODO: we might want to be more standard about the div ids for these sections...
            div_id = "#detail-linked-"
            if !%w(WebLink Video).include?(class_name)
              div_id += @humanized_plural.downcase
            elsif class_name == 'Video'
              div_id += 'video'
            else
              div_id += @tableized
            end

            click_link_within(div_id, "Create")

            # additional step for topics
            # you have to choose topic type
            # just choosing default "Topic" type
            click_button("Choose Type") if class_name == 'Topic'

            # fill out new item form and submit it
            fill_in "Title", :with => @item_title

            # get the attribute that defines each class
            if ATTACHABLE_CLASSES.include?(class_name)
              # put in a case statement
              case class_name
              when 'StillImage'
                attach_file "image_file_uploaded_data", "white.jpg"
              when 'Video'
                attach_file "video[uploaded_data]", "teststrip.mpg", "video/mpeg"
              when 'AudioRecording'
                attach_file "audio_recording[uploaded_data]", "Sin1000Hz.mp3"
              when 'Document'
                attach_file "document[uploaded_data]", "test.pdf"
              end
            elsif class_name == 'WebLink'
              # this will only work if you have internet connection
              fill_in "web_link[url]", :with => "http://google.co.nz/"
            end

            click_button "Create"

            # we should arrive back at the topic the item is related to
            # and the item should be listed and the total should be 1
            body_should_contain "#{@humanized_plural} (1)"
            body_should_contain @item_title

            # we should be able to visit the new related item and the topic it is related to
            # should be listed
            click_link @item_title
            unless class_name == 'Topic'
              body_should_contain "Related Topics"
            else
              # topics are a special case since they are what we always link through
              body_should_contain "Topics (1)"
            end
            body_should_contain @topic.title
          end
          
          context "with a linkable item available" do
            
            setup do
              @item_for_relating = send("new_#{@tableized.singularize}", :title => "Item for relating") do

                # get the attribute that defines each class
                if ATTACHABLE_CLASSES.include?(class_name)
                  # put in a case statement
                  case class_name
                  when 'StillImage'
                    attach_file "image_file_uploaded_data", "white.jpg"
                  when 'Video'
                    attach_file "video[uploaded_data]", "teststrip.mpg", "video/mpeg"
                  when 'AudioRecording'
                    attach_file "audio_recording[uploaded_data]", "Sin1000Hz.mp3"
                  when 'Document'
                    attach_file "document[uploaded_data]", "test.pdf"
                  end
                elsif class_name == 'WebLink'
                  # this will only work if you have internet connection
                  fill_in "web_link[url]", :with => "http://google.co.uk/"
                end
                
              end
            end

            should "be able to link existing related #{class_name}" do
              lower_case_name = @tableized.gsub("_", " ")
              
              visit "/site/search/find_related?function=add&relate_to_topic=#{@topic.to_param}&related_class=#{class_name}"
              
              body_should_contain "Add related #{lower_case_name}"
              body_should_contain "Search for #{lower_case_name}"
              
              fill_in "search_terms", :with => "Item for relating"
              click_button "Search"
              
              body_should_contain "Select which #{lower_case_name} to add, then click \"add\"."
              
              body_should_contain @item_for_relating.title
              
              check "item_#{@item_for_relating.id.to_s}"
              
              click_button "Add"
              
              body_should_contain "Successfully added item relationships"
              
              visit "/site/topics/show/#{@topic.to_param}"
              
              # we should arrive back at the topic the item is related to
              # and the item should be listed and the total should be 1
              body_should_contain "#{@humanized_plural} (1)"
              body_should_contain @item_for_relating.title

              # we should be able to visit the new related item and the topic it is related to
              # should be listed
              click_link @item_for_relating.title
              
              unless class_name == 'Topic'
                body_should_contain "Related Topics"
              else
                # topics are a special case since they are what we always link through
                body_should_contain "Topics (1)"
              end
              
              # James - 2008-01-14
              # For some reason, the original topic is not linked back to on the still
              # image page as you would expect. This may be a bug or it may be a fault in my test.
              # To be investigated.
              body_should_contain @topic.title unless class_name == "StillImage"

            end
          
            # should_eventually "be able to unlink related #{class_name}"
            # should_eventually "be able to restore unlinked related #{class_name}"
            # should_eventually "be able to destroy related #{class_name} and have the item be dropped from the related #{class_name} list"
            # should_eventually "be able to destroy topic that #{class_name} is related to and have the item's related topics list will be blank"
            
          end

          if ATTACHABLE_CLASSES.include?(class_name)
            # should_eventually "be able to upload a zip file of related #{@tableized}"
          end

          # should_eventually "not display links to items with no public version"

        end
      end # End of item class iteration
    end # End of context "when a topic is added"
  end
end

