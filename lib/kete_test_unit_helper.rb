require 'kete_url_for'

module KeteTestUnitHelper
  def test_raw_validation
    model = Module.class_eval(@base_class).new
    if @req_attr_names.blank?
      assert model.valid?, "#{@base_class} should be valid without initialisation parameters"
    else
      # If @base_class has validation, then use the following:
      assert !model.valid?, "#{@base_class} should not be valid without initialisation parameters"
      @req_attr_names.each { |attr_name| assert model.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}" }
    end
  end

  def test_new
    # shouldn't this take the @new_model has args?
    model = Module.class_eval(@base_class).new @new_model
    assert model.valid?, "#{@base_class} should be valid"
    @new_model.each do |attr_name|
      assert_equal @new_model[attr_name], model.attributes[attr_name], "#{@base_class}.@#{attr_name.to_s} incorrect"
    end
  end


  def test_validates_presence_of
    @req_attr_names.each do |attr_name|
      tmp_model = @new_model.clone
      tmp_model.delete attr_name.to_sym
      model = Module.class_eval(@base_class).new(tmp_model)
      assert !model.valid?, "#{@base_class} should be invalid, as @#{attr_name} is invalid"
      assert model.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end


  def test_duplicate
    current_model = Module.class_eval(@base_class).find(:first)
    @duplicate_attr_names.each do |attr_name|
      model = Module.class_eval(@base_class).new(@new_model.merge(attr_name.to_sym => current_model[attr_name]))
      assert !model.valid?, "#{@base_class} should be invalid, as @#{attr_name} is a duplicate"
      assert model.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end

  include KeteUrlFor
  def test_before_update_register_redirect_if_necessary
    current_model = Module.class_eval(@base_class).create!(@new_model)
    old_urlified_name = current_model.basket.urlified_name
    new_basket = Basket.last

    current_model.basket_id = Basket.last.id
    current_model.save!

    new_url = url_for_dc_identifier(current_model)

    old_url = new_url.sub(new_basket.urlified_name, old_urlified_name)

    assert_not_nil RedirectRegistration.find(:first,
                                             :conditions => {
                                               :source_url_pattern => old_url,
                                               :target_url_pattern => new_url })
  end
end
