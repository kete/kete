module ImportersHelper
  def xml_type_js_observer
    raise "BOOM"
  end

  def zoom_class_js_observer
    raise "BOOM"
  end

  def record_identifier_js_observer
    raise "BOOM"
  end

  def related_topics_js_observer
    raise "BOOM"
  end

  # dynamically define query methods for our attribute specs
  def self.define_options_method_for(constant_name)
    method_name = constant_name.downcase + '_as_options'

    # create the template code
    code = Proc.new {
      options = Array.new
      constant_name.constantize.each do |item_class_name|
        selected = (@zoom_class_name == item_class_name) ? " selected='selected'" : ''
        options << "<option value='#{item_class_name}'#{selected}>#{zoom_class_plural_humanize(item_class_name)}</option>"
      end
      options.join('')
    }

    define_method(method_name, &code)
  end

  ["ATTACHABLE_CLASSES", "ITEM_CLASSES"].each { |constant_name| define_options_method_for(constant_name) }

end
