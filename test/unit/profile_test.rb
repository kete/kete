require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  should_have_many :profile_mappings, :dependent => :destroy
  should_have_many :baskets, :through => :profile_mappings

  # available_to_models is automatically set to 'Basket'
  # with a before_validation filter for the time being
  # as baskets are the only thing that currently use profiles
  # in the future, if profiles are used in other aspects of kete
  # we'll want to use the commented out test
  # in the meantime, we test that available_to_models is always 'Basket
  # should_require_attributes :name, :available_to_models
  should_require_attributes :name

  context "The Profile class" do
    should "have valid type_options" do
      options_spec = [ ['None', 'none'],
                       ['All', 'all'],
                       ['Select Below', 'some']
                     ]
      assert_equal Profile.type_options, options_spec
    end
  end

  context "A Profile" do
    should "be able to set and get the rules during creation" do
      the_form = Basket::FORMS_OPTIONS.first[1]
      the_type = Profile.type_options.first[1]
      the_rules = { the_form => the_type }
      @profile = Profile.create!(:name => 'Test', :rules => the_rules)
      @profile.reload
      assert_equal the_rules, @profile.rules(true)
    end

    context "after being created" do
      setup do
        @profile = Profile.create!(:name => 'Test')
      end

      should "always have a available_to_models attribute with Basket as the value" do
        assert_equal 'Basket', @profile.available_to_models
      end

      should "be able to populate a rules setting" do
        @profile.settings[:rules] = 'there are no rules!'
        assert_equal 'there are no rules!', @profile.settings[:rules]
      end
    end
  end
end
