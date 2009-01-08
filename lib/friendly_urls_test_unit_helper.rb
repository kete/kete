module FriendlyUrlsTestUnitHelper
  include FriendlyUrls

  # TODO: test case unicode
  def test_format_friendly_for
    # call to format_friendly_for is BROKEN
    format_friendly = format_friendly_for('something wicked this way comes!')
    assert_equal '-something-wicked-this-way-comes', format_friendly, "#{@base_class}. format_friendly_for failed"
  end

  # TODO: test that is retains unicode
  def test_format_friendly_unicode_for
    # call to format_friendly_for is BROKEN
    format_friendly = format_friendly_unicode_for('something wicked this way comes!')
    assert_equal '-something-wicked-this-way-comes', format_friendly, "#{@base_class}. format_friendly_unicode_for failed"

    format_friendly = format_friendly_unicode_for('something wicked this way comes!', :demarkator => "_", :at_end => true, :at_start => false)
    assert_equal 'something_wicked_this_way_comes_', format_friendly, "#{@base_class}. format_friendly_unicode_for failed"
  end

  def test_format_for_friendly_urls
    model = Module.class_eval(@base_class).create! @new_model
    formatted_title = model.format_for_friendly_urls

    # make sure the url starts with correct id
    re = Regexp.new("^[^-]+")
    friendly_id = formatted_title.scan(re)[0]
    assert_equal model.id.to_s, friendly_id.to_s, "#{@base_class}.format_for_friendly_urls didn't match the id of the model"

    # make sure that formatting is correct
    model.update_attributes(:title => 'something else!')
    assert_equal model.id.to_s + '-something-else', model.format_for_friendly_urls, "#{@base_class}.format_for_friendly_urls didn't format the title correctly"
  end

end
