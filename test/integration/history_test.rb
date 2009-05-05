require File.dirname(__FILE__) + '/integration_test_helper'

class HistoryTest < ActionController::IntegrationTest

  ITEM_CLASSES.each do |item_class|

    context "The history page for a #{item_class}" do

      setup do
        add_admin_as_super_user
        add_dean_as_regular_user
        add_angela_as_regular_user
        add_rach_as_regular_user

        login_as('dean')
        @item = new_item({ :title => 'History Test v1' }, nil, nil, item_class) do
          fill_in_needed_information_for(item_class)
        end
        login_as('angela')
        @item = update_item(@item, { :title => 'History Test v2' })
        login_as('rach')
        @item = update_item(@item, { :title => 'History Test v3' })
        login_as('admin')
      end

      should "show all versions and have correct contributors" do
        visit "/#{@item.basket.urlified_name}/#{zoom_class_controller(item_class)}/history/#{@item.id}"
        body_should_contain '# 1', :number_of_times => 1
        body_should_contain '>dean<', :number_of_times => 1
        body_should_contain '# 2', :number_of_times => 1
        body_should_contain '>angela<', :number_of_times => 1
        body_should_contain '# 3', :number_of_times => 1
        body_should_contain '>rach<', :number_of_times => 1
      end

      should "show the flags when they have them" do
        @item = flag_item_with(@item, :duplicate)
        @item = flag_item_with(@item, :inaccurate)

        visit "/#{@item.basket.urlified_name}/#{zoom_class_controller(item_class)}/history/#{@item.id}"
        body_should_contain 'duplicate', :number_of_times => 1
        body_should_contain 'inaccurate', :number_of_times => 1
      end

    end

  end

end
