require File.dirname(__FILE__) + '/integration_test_helper'

::ActionController::UrlWriter.module_eval do
  default_url_options[:host] = SITE_NAME
end

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
              # HACK: lingering items for relating polluting our tests
              # Clean the zebra instance to give us a clean state to check against
              # this gets repeated 6 times (at this point)
              # so will slow performance of our tests...
              # TODO: figure out why old instances of item_for_relating
              # 4 or them when there should be 1
              # are showing up as a side effect of other tests
              # explicit teardown zoom_destroy calls may be necessary
              # for the other tests
              bootstrap_zebra_with_initial_records
              @topic.prepare_and_save_to_zoom
              @item_for_relating.prepare_and_save_to_zoom

              visit "/site/topics/show/#{@topic.to_param}"
              click_link 'Link Existing'
              click_link @item_type unless class_name == 'Topic' # Topic is already the default

              lower_case_name = @humanized_plural.downcase
              body_should_contain "Add related #{lower_case_name}"
              body_should_contain "Search for public #{lower_case_name}"

              fill_in "search_terms", :with => @item_for_relating.title
              click_button "Search"

              body_should_contain I18n.t('search.related_form.select_items',
                                         :item_class => lower_case_name,
                                         :action => 'Add')
              body_should_contain @item_for_relating.title

              check "item_#{@item_for_relating.id.to_s}"
              click_button "Add"

              body_should_contain I18n.t('application_controller.link_related.added_relation')

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

              body_should_contain I18n.t('search.related_form.title',
                                         :action => 'Remove',
                                         :zoom_class_plural => lower_case_name)
              body_should_contain @item_for_relating.title

              check "item_#{@item_for_relating.id.to_s}"
              click_button "Remove"

              body_should_contain I18n.t('application_controller.unlink_related.unlinked_relation')

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

  context "The caching issue with related items" do
    setup do
      enable_production_mode
      add_jerry_as_super_user
      login_as('jerry')
      @parent_topic = new_topic(:title => 'Parent Topic')
    end

    teardown do
      disable_production_mode
    end

    ITEM_CLASSES.each do |zoom_class|
      context "when a #{zoom_class} is added" do
        setup do
          @related_item = send("new_#{zoom_class.tableize.singularize}",
                               { :title => 'Child Item 1', :relate_to => @parent_topic }) do |field_prefix|
            fill_in_needed_information_for(zoom_class)
          end
        end

        should "not show up in the parent topic if the child item is deleted" do
          # delete the related item
          old_title = @related_item.title
          @related_item = delete_item(@related_item)

          # check the parent topic still works
          item_url = "/#{@parent_topic.basket.urlified_name}/#{zoom_class_controller(@parent_topic.class.name)}/show/#{@parent_topic.id}"
          visit item_url
          body_should_not_contain '500 Error!'
          body_should_contain @parent_topic.title
          body_should_not_contain old_title
          visit item_url
          body_should_not_contain '500 Error!'
        end

        should "not show up in the related item if the parent topic is deleted" do
          # delete the parent item
          old_title = @parent_topic.title
          @parent_topic = delete_item(@parent_topic)

          # check the child item still works
          item_url = "/#{@related_item.basket.urlified_name}/#{zoom_class_controller(@related_item.class.name)}/show/#{@related_item.id}"
          visit item_url
          body_should_not_contain '500 Error!'
          body_should_contain @related_item.title
          body_should_not_contain old_title
          visit item_url
          body_should_not_contain '500 Error!'
        end

        should "not show up if a different related item is deleted" do
          @related_item2 = send("new_#{zoom_class.tableize.singularize}",
                                { :title => 'Child Item 2', :relate_to => @parent_topic }) do |field_prefix|
            fill_in_needed_information_for(zoom_class)
          end

          # delete one of the two related items
          old_title = @related_item.title
          @related_item = delete_item(@related_item)

          # check the parent topic still works
          visit "/#{@parent_topic.basket.urlified_name}/#{zoom_class_controller(@parent_topic.class.name)}/show/#{@parent_topic.id}"
          body_should_not_contain '500 Error!'
          body_should_contain @parent_topic.title
          body_should_not_contain old_title

          # check the other related item still works
          item_url = "/#{@related_item2.basket.urlified_name}/#{zoom_class_controller(@related_item2.class.name)}/show/#{@related_item2.id}"
          visit item_url
          body_should_not_contain '500 Error!'
          body_should_contain @related_item2.title
          visit item_url
          body_should_not_contain '500 Error!'
        end
      end
    end

    #
    # WARNING
    # These import tests require backgroundrb be enabled and in production mode
    # They also take a considerable amount of time (2 minutes per zoom class X 4 zoom classes = at least 8 minutes)
    # So aren't run by default. To run the tasks, set the following before the rake task:
    #   BGRB=true
    # Also, make sure you have started backgroundrb in test mode (not production or development)
    #   script/backgroundrb start --environment=test

    if ENV['BGRB'] == 'true'

      puts "-------------------------------------------------------------------------------------------------------"
      puts "Some of the tests will require long periods of waiting (because they involve backgroundrb)."
      puts "During those tests, every 10 seconds the output will show a 'W' (waiting) to indicate processing."
      puts "If the BGRB worker fails, the output will show a 'T' (timeout failure), but continue with other tests."
      puts "-------------------------------------------------------------------------------------------------------"

      ATTACHABLE_CLASSES.each do |zoom_class|
        context "when a set of #{zoom_class} are imported" do
          setup do
            visit "/#{@parent_topic.basket.urlified_name}/#{zoom_class_controller(@parent_topic.class.name)}/show/#{@parent_topic.id}"
            click_link 'Import Set'
            body_should_contain 'Add related set of items'
            select zoom_class_plural_humanize(zoom_class), :from => 'zoom_class'
            attach_file 'import_archive_file_uploaded_data', "#{zoom_class.tableize.singularize}_files.zip"
            count_before = zoom_class.constantize.count
            click_button "Add Related Items"
            body_should_contain "Import from #{zoom_class.tableize.singularize}_files.zip"

            count = 0
            @timeout = false
            while !@timeout && ((count_before + 2) > zoom_class.constantize.count)
              # timeout if its been longer than 60 seconds
              if count == 6
                @timeout = true
                $stdout.print 'T'
              else
                count += 1
                $stdout.print 'W'
                sleep 10
              end
            end
            assert false if @timeout
            @related_item1, @related_item2 = zoom_class.constantize.all[-2..-1]
          end

          should "have imported fully with all related links setup" do
            # check the related items are listed in parent topic
            visit "/#{@parent_topic.basket.urlified_name}/#{zoom_class_controller(@parent_topic.class.name)}/show/#{@parent_topic.id}"
            body_should_contain @related_item1.title
            body_should_contain @related_item2.title

            # check the parent item is listed in related item 1
            visit "/#{@related_item1.basket.urlified_name}/#{zoom_class_controller(@related_item1.class.name)}/show/#{@related_item1.id}"
            body_should_contain @parent_topic.title

            # check the parent item is listed in related item 2
            visit "/#{@related_item2.basket.urlified_name}/#{zoom_class_controller(@related_item2.class.name)}/show/#{@related_item2.id}"
            body_should_contain @parent_topic.title
          end

          should "not show up in the parent topic if the child item is deleted" do
            # delete the related item
            old_title = @related_item1.title
            @related_item1 = delete_item(@related_item1)

            # check the parent topic still works
            item_url = "/#{@parent_topic.basket.urlified_name}/#{zoom_class_controller(@parent_topic.class.name)}/show/#{@parent_topic.id}"
            visit item_url
            body_should_not_contain '500 Error!'
            body_should_contain @parent_topic.title
            body_should_not_contain old_title
            visit item_url
            body_should_not_contain '500 Error!'
          end

          should "not show up in the related item if the parent topic is deleted" do
            # delete the parent item
            old_title = @parent_topic.title
            @parent_topic = delete_item(@parent_topic)

            # check the child item still works
            item_url = "/#{@related_item1.basket.urlified_name}/#{zoom_class_controller(@related_item1.class.name)}/show/#{@related_item1.id}"
            visit item_url
            body_should_not_contain '500 Error!'
            body_should_contain @related_item1.title
            body_should_not_contain old_title
            visit item_url
            body_should_not_contain '500 Error!'
          end

          should "not show up if a different related item is deleted" do
            # delete one of the two related items
            old_title = @related_item1.title
            @related_item1 = delete_item(@related_item1)

            # check the parent topic still works
            visit "/#{@parent_topic.basket.urlified_name}/#{zoom_class_controller(@parent_topic.class.name)}/show/#{@parent_topic.id}"
            body_should_not_contain '500 Error!'
            body_should_contain @parent_topic.title
            body_should_not_contain old_title

            # check the other related item still works
            item_url = "/#{@related_item2.basket.urlified_name}/#{zoom_class_controller(@related_item2.class.name)}/show/#{@related_item2.id}"
            visit item_url
            body_should_not_contain '500 Error!'
            body_should_contain @related_item2.title
            visit item_url
            body_should_not_contain '500 Error!'
          end
        end
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
