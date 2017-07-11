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
    Basket.find(:first).set_setting :fully_moderated, true

    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 2 since a new blank version should be automatically added
    # it shouldn't have any flags on the live version
    assert_equal 2, model.version
    assert_equal SystemSetting.blank_title, model.title
    assert_equal 0, model.versions.find_by_version(model.version).tags.size

    # first version should be flagged as pending
    assert model.versions.find_by_version(1).tags.include?(Tag.find_by_name(SystemSetting.pending_flag))
  end

  def test_fully_moderated_basket_but_excepted_class_add_succeeds
    # make the basket require moderation
    @basket = Basket.find(:first)
    @basket.set_setting :fully_moderated, true

    # but make this class be listed as free of moderation
    @basket.set_setting :moderated_except, [@base_class]

    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 1
    assert_equal 1, model.version
    # no flags on version
    assert_equal 0, model.versions.find_by_version(1).tags.size
  end

  def test_version_class_contains_flagging_boolean_methods
    @base_class.constantize.create!(@new_model)
    @version = @base_class.constantize::Version.first

    assert @version.respond_to?(:disputed?)
    assert @version.respond_to?(:reviewed?)
    assert @version.respond_to?(:rejected?)
  end

  def test_find_flagged_returns_as_expected
    @basket = Basket.find(:first)

    not_flagged = @base_class.constantize.create!(@new_model.merge(title: 'not flagged'))

    flagged_items = Array.new
    %w{ flagged1 flagged2 flagged3 }.each do |title|
      @new_model = @new_model.merge(url: "http://google.com/#{(rand * 10000).to_i}") if @base_class == 'WebLink'
      model = @base_class.constantize.create!(@new_model.merge(title: title))
      model.flag_at_with(1, 'bad title')
      flagged_items << model
    end

    flagged_items[0].review_this(1)
    flagged_items[2].reject_this(1)

    result = @base_class.constantize.find_flagged(@basket)

    assert_equal 3, result.size

    assert result[0].reviewed?
    assert result[1].disputed?
    assert result[2].rejected?
  end

end
