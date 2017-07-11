module FriendlyUrlsTestUnitHelper
  include FriendlyUrls

  # TODO: test case unicode
  def test_format_friendly_for
    format_friendly = format_friendly_for('something wicked this way comes!')
    assert_equal '-something-wicked-this-way-comes', format_friendly, "#{@base_class}. format_friendly_for failed"

    # this tests that transliteration is done
    format_friendly = format_friendly_for('āēīōū and in your 家!')
    assert_equal '-aeiou-and-in-your', format_friendly, "#{@base_class}. format_friendly_for failed"
  end

  def test_format_friendly_unicode_for
    format_friendly = format_friendly_unicode_for('something wicked this way comes!')
    assert_equal '-something-wicked-this-way-comes', format_friendly, "#{@base_class}. format_friendly_unicode_for failed"

    format_friendly = format_friendly_unicode_for('something wicked this way comes!', demarkator: '_', at_end: true, at_start: false)
    assert_equal 'something_wicked_this_way_comes_', format_friendly, "#{@base_class}. format_friendly_unicode_for failed"

    format_friendly = format_friendly_unicode_for('& it is āēīōū and in your 家!')
    assert_equal '-and-it-is-āēīōū-and-in-your-家', format_friendly, "#{@base_class}. format_friendly_unicode_for failed"
  end

  def test_format_for_friendly_urls
    title_or_name_attr = @base_class == 'Basket' ? :name : :title

    model = Module.class_eval(@base_class).create! @new_model
    formatted_title = model.format_for_friendly_urls

    # make sure the url starts with correct id
    re = Regexp.new('^[^-]+')
    friendly_id = formatted_title.scan(re)[0]
    assert_equal model.id.to_s, friendly_id.to_s, "#{@base_class}.format_for_friendly_urls didn't match the id of the model"

    # make sure that formatting is correct
    model.update_attributes(title_or_name_attr => 'something else!')
    assert_equal model.id.to_s + '-something-else', model.format_for_friendly_urls, "#{@base_class}.format_for_friendly_urls didn't format the #{title_or_name_attr} correctly"

    # test selection of title/name in find(:all) queries still works as intended
    # test both types of selections:
    #   :select => 'name'
    #   :select => 'basket.name'
    ["#{title_or_name_attr}", "#{@base_class.tableize}.#{title_or_name_attr}"].each do |select_type|
      selected_model = @base_class.constantize.find(:all, select: "#{select_type}, created_at").last
      assert_equal selected_model.id.to_s + '-something-else', selected_model.format_for_friendly_urls, "#{@base_class}.format_for_friendly_urls didn't format the #{title_or_name_attr} correctly"
    end
  end

end
