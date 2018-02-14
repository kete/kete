# frozen_string_literal: true

# Walter McGinnis, 2007-11-02
# test that correspond to HasContributors Module
module HasContributorsTestUnitHelper
  # can we add a user in the role of creator to this item
  def test_add_creator
    model = Module.class_eval(@base_class).create! @new_model
    user = User.find(1)

    model.creators << user

    # test that we have a creator for that item
    assert_equal 1, model.creators.size, "#{@base_class} failed to add creator"
  end

  # can we add a user in the role of creator to this item
  def test_add_contributor
    model = Module.class_eval(@base_class).create! @new_model
    user = User.find(:first)

    # add creator first, because first contributor is always creator role
    model.creators << user

    # update model to have new version
    model.update_attributes(title: 'something else')

    # make sure that version is 2
    assert_equal 2, model.version, "#{@base_class} failed didn't update version"

    # now add the contributor of the new version
    model.add_as_contributor(user)

    # test that we have a contributor for that item
    assert_equal 1, model.contributors.size, "#{@base_class} failed to add contributor"
  end
end
