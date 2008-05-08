# TODO: add coverage of basic flagging functionality
# non-fully moderated tests
# fully moderated tests
# fully moderated except specified zoom classes tests
module FlaggingTestUnitHelper
  def test_not_fully_moderated_add_succeeds
    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 1
    assert_equal 1, model.version
    # no flags on version
    assert_equal 0, model.versions.find_by_version(1).tags.size
  end

  def test_fully_moderated_add_flags_version_as_pending_and_creates_blank_current_version
    # make the basket require moderation
    Basket.find(:first).settings[:fully_moderated] = true

    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 2 since a new blank version should be automatically added
    # it shouldn't have any flags on the live version
    assert_equal 2, model.version
    assert_equal BLANK_TITLE, model.title
    assert_equal 0, model.versions.find_by_version(model.version).tags.size

    # first version should be flagged as pending
    assert model.versions.find_by_version(1).tags.include?(Tag.find_by_name(PENDING_FLAG))
  end
end
