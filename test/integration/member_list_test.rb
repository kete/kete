require File.dirname(__FILE__) + '/integration_test_helper'

class MemberListTest < ActionController::IntegrationTest

  context "A Member List" do

    setup do
      @joe = Factory(:user, :login => 'joe')
      @joe.add_as_member_to_default_baskets
      @bob = Factory(:user, :login => 'bob')
      @bob.add_as_member_to_default_baskets
      @john = Factory(:user, :login => 'joe')
      @john.add_as_member_to_default_baskets
    end

    #should "" do
    #  
    #end

  end

end
