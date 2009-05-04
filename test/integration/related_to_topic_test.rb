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
            @item_controller = zoom_class_controller(class_name)
            @tableized = class_name.tableize
            @item_title = "Related #{@item_type}"
          end

          should "be empty to start" do
            body_should_contain "#{@humanized_plural} (0)"
          end

          should "be able to create related #{class_name}" do
            click_link "Create"
            select @item_type, :from => 'new_item_controller'
            click_button "Choose"
            click_button "Choose Type" if @item_type == 'Topic'
            body_should_contain "New #{@item_type}"

            # fill out new item form and submit it
            fill_in "Title", :with => @item_title
            fill_in_needed_information_for(class_name)
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
                fill_in_needed_information_for(class_name)
              end
            end

            should "be able to link existing related #{class_name}" do
              visit "/site/topics/show/#{@topic.to_param}"
              click_link 'Link Existing'
              click_link @item_type unless class_name == 'Topic' # Topic is already the default

              lower_case_name = @humanized_plural.downcase
              body_should_contain "Add related #{lower_case_name}"
              body_should_contain "Search for public #{lower_case_name}"

              fill_in "search_terms", :with => @item_for_relating.title
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

              body_should_contain @topic.title
            end

          end

          context "which has been added to a topic" do

            setup do
              @item_for_relating = send("new_#{@tableized.singularize}", :title => "Item for relating", :relate_to => @topic) do
                fill_in_needed_information_for(class_name)
              end
            end

            should "be able to unlink related #{class_name}" do
              visit "/site/topics/show/#{@topic.to_param}"

              body_should_contain "#{@humanized_plural} (1)"
              body_should_contain @item_for_relating.title

              click_link 'Remove'
              click_link @item_type unless class_name == 'Topic' # Topic is already the default

              lower_case_name = @humanized_plural.downcase
              body_should_contain "Existing related #{lower_case_name}"
              body_should_contain @item_for_relating.title

              check "item_#{@item_for_relating.id.to_s}"
              click_button "Remove"

              body_should_contain 'Successfully removed item relationships.'

              visit "/site/topics/show/#{@topic.to_param}"

              body_should_contain "#{@humanized_plural} (0)"
              body_should_not_contain @item_for_relating.title
            end

            context "and then removed from the item" do

              setup do
                ContentItemRelation.destroy_relation_to_topic(@topic, @item_for_relating)
                Rake::Task['tmp:cache:clear'].execute(ENV)
              end

              should "be able to restore unlinked related #{class_name}" do
                add_john_as_moderator_to(@@site_basket)

                visit "/site/topics/show/#{@topic.to_param}"

                body_should_contain "#{@humanized_plural} (0)"
                body_should_not_contain @item_for_relating.title

                click_link 'Restore (1)'
                click_link @item_type unless class_name == 'Topic' # Topic is already the default

                lower_case_name = @humanized_plural.downcase
                body_should_contain "Restore related #{lower_case_name}"
                body_should_contain @item_for_relating.title

                check "item_#{@item_for_relating.id.to_s}"
                click_button "Restore"

                body_should_contain 'Successfully added item relationships'

                visit "/site/topics/show/#{@topic.to_param}"

                body_should_contain "#{@humanized_plural} (1)"
                body_should_contain @item_for_relating.title
              end

            end

            should "be dropped from the parent related #{class_name} list when the child item is destroyed" do
              add_john_as_moderator_to(@@site_basket)

              visit "/site/topics/show/#{@topic.to_param}"
              body_should_contain "#{@humanized_plural} (1)"
              body_should_contain @item_for_relating.title

              visit "/site/#{@item_controller}/show/#{@item_for_relating.to_param}"
              body_should_contain @topic.title

              click_link 'Delete'

              visit "/site/topics/show/#{@topic.to_param}"
              body_should_contain "#{@humanized_plural} (0)"
              body_should_not_contain @item_for_relating.title
            end

            should "be dropped from the child related #{class_name} list when the parent item is destroyed" do
              add_john_as_moderator_to(@@site_basket)

              visit "/site/#{@item_controller}/show/#{@item_for_relating.to_param}"
              body_should_contain @topic.title

              visit "/site/topics/show/#{@topic.to_param}"
              body_should_contain "#{@humanized_plural} (1)"
              body_should_contain @item_for_relating.title

              click_link 'Delete'

              visit "/site/#{@item_controller}/show/#{@item_for_relating.to_param}"
              body_should_not_contain @topic.title
            end

          end

          # if ATTACHABLE_CLASSES.include?(class_name)
          #   # should_eventually "be able to upload a zip file of related #{@tableized}"
          # end

        end
      end # End of item class iteration
    end # End of context "when a topic is added"

    context "when a private related topic is added" do

      setup do
        @@site_basket.update_attributes({ :show_privacy_controls => true })
        @topic1 = new_topic({ :title => 'Parent Topic' })
        @topic2 = new_topic({ :title => 'Child Topic 1', :private_true => true, :relate_to => @topic1, :go_to_related => false })
      end

      teardown do
        @@site_basket.update_attributes({ :show_privacy_controls => false })
      end

      should "show up for members or higher" do
        body_should_contain 'Topics (1)'
      end

      should "not show up for logged out users or non basket members" do
        add_larry
        login_as('larry')
        check_private_topics_not_showing
        logout
        check_private_topics_not_showing
      end

    end

  end

  private

  def check_private_topics_not_showing
    visit "/site/topics/show/#{@topic1.to_param}"
    body_should_contain 'Topics (0)'
    body_should_not_contain 'Child Topic 1'
    body_should_not_contain "/site/topics/show/#{@topic2.id}?private=true"
  end

end

