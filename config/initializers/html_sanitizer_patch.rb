module HTML
  class WhiteListSanitizer < Sanitizer
    protected
    def process_attributes_for(node, options)
      return unless node.attributes
      node.attributes.keys.each do |attr_name|
        value = node.attributes[attr_name].to_s

        if !options[:attributes].include?(attr_name) || contains_bad_protocols?(attr_name, value)
          node.attributes.delete(attr_name)
        else
          node.attributes[attr_name] = attr_name == 'style' ? sanitize_css(value) : CGI::escapeHTML(CGI::unescapeHTML(value))
        end
      end
    end
  end
end
