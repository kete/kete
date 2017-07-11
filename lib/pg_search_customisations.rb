module PgSearchCustomisations

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods

    # * this is the method that PgSearch calls to rebuild the index for a model
    # * override it because PgSearch default does not work with dynamic
    #   attributes (which we use for extended content)
    def rebuild_pg_search_documents
      all.each do |record|
        record.update_pg_search_document
      end
    end
  end

  module InstanceMethods

    # * extract the values from the XML in the model's 'extended_content' attribute
    # * return them as a concatentated string suitable for adding to the search index
    def searchable_extended_content_values
      return '' if extended_content.blank? || extended_content.nil?

      # * extended_content_values returns a hash similar to:
      #
      #     "source" => {
      #       "xml_element_name" => "dc:source"
      #     },
      #     "user_reference" => {
      #       "xml_element_name" => "dc:identifier"
      #       "value" => "foo"
      #     }
      #
      # * we just want the contents of the 'value' key

      values = extended_content_values.values.map do |value|
        (value.class == Hash) ? value['value'] : value
      end

      values.join(' ').squish
    end
  end
end
