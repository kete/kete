require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  # quick and simple association testing
  should have_many(:profile_mappings).dependent(:destroy)
  should have_many(:baskets).through(:profile_mappings)

  # available_to_models is automatically set to 'Basket'
  # with a before_validation filter for the time being
  # as baskets are the only thing that currently use profiles
  # in the future, if profiles are used in other aspects of kete
  # we'll want to use the commented out test
  # in the meantime, we test that available_to_models is always 'Basket
  # should validate_presence_of :name, :available_to_models
  should validate_presence_of :name

  context "The Profile class" do
    should "have valid type_options" do
      options_spec = [ ['None', 'none'],
                       ['All', 'all'],
                       ['Select Below', 'some'] ]
      assert_equal Profile.type_options, options_spec
    end
  end

  context "A Profile" do
    should "be able to set and get the rules during creation" do
      the_form = Basket.forms_options.first[1]
      the_type = Profile.type_options.first[1]
      the_rules = { the_form => { 'rule_type' => the_type } }
      profile = Factory(:profile, :rules => the_rules)
      assert_equal the_rules, profile.rules(true)
    end

    should "require that a rule_type be set for each form type" do
      profile = Factory.build(:profile, :rules => { 'edit' => {} })
      assert !profile.valid?
      assert_equal 'The following forms are missing a rule type: Edit', profile.errors['base']
    end

    context "after being created" do
      setup do
        @profile = Factory(:profile)
      end

      should "always have a available_to_models attribute with Basket as the value" do
        assert_equal 'Basket', @profile.available_to_models
      end

      should "be able to populate a rules setting" do
        @profile.settings[:rules] = 'there are no rules!'
        assert_equal 'there are no rules!', @profile.settings[:rules]
      end

      should "be able to access a user readable version of the rules" do
        assert_equal 'Edit: None.', @profile.rules
      end

      should "be able to access a raw hash version of the rules" do
        result = { 'edit' => { 'rule_type' => 'none' } }
        assert_equal result, @profile.rules(true)
      end

      should "not be able to be edited/updated" do
        profile = Factory(:profile)
        assert !profile.authorized_for_update?
        assert !profile.authorized_for?(:action => :update)
      end

      should "only be deletable when there are no profile mappings" do
        profile = Factory(:profile)
        assert profile.authorized_for_destroy?
        assert profile.authorized_for?(:action => :destroy)

        basket = Factory(:basket)
        basket.profiles << profile

        profile.reload
        assert !profile.authorized_for_destroy?
        assert !profile.authorized_for?(:action => :destroy)
      end
    end
  end
end
