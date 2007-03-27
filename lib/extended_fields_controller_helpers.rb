# related to extended_fields for content_types
module ExtendedFieldsControllerHelpers
  unless included_modules.include? ExtendedFieldsControllerHelpers
    # populate extended_fields param with xml
    # based on params from the form
    def extended_fields_update_hash_for_item(options = {})
      item_key = options[:item_key].to_sym
      logger.debug("inside update param for item")
      params.each do |key,value|
        logger.debug("what is #{key}: #{value.to_s}")
      end

      params[item_key][:extended_content] = render_to_string(:partial => 'search/field_to_xml',
                                                             :collection => @fields,
                                                             :layout => false,
                                                             :locals => { :item_key => item_key})
      logger.debug("after field_to_xml")
      return params
    end

    alias extended_fields_update_param_for_item extended_fields_update_hash_for_item

    # strip out raw extended_fields and create a valid params hash for new/create/update
    def extended_fields_replacement_params_hash(options = {})
      item_key = options[:item_key].to_sym
      item_class = options[:item_class]

      extra_fields = options[:extra_fields] || Array.new
      extra_fields << 'tag_list'
      extra_fields << 'uploaded_data'

      logger.debug("what are extra fields : #{extra_fields.to_s}")
      replacement_hash = Hash.new

      params[item_key].keys.each do |field_key|
        # we only want real topic columns, not pseudo ones that are handled by extended_content xml
        if Module.class_eval(item_class).column_names.include?(field_key) || extra_fields.include?(field_key)
          replacement_hash = replacement_hash.merge(field_key => params[item_key][field_key])
        end
      end
      logger.debug("end of replacement")
      return replacement_hash
    end

    def extended_fields_and_params_hash_prepare(options = {})
      item_key = options[:item_key]
      item_class = options[:item_class]
      content_type = options[:content_type]
      extra_fields = options[:extra_fields] || Array.new

      logger.debug("inside prepare")
      # grab the content_type fields
      @fields = content_type.content_type_to_field_mappings

      if @fields.size > 0
        extended_fields_update_param_for_item(:fields => @fields, :item_key => item_key)
      end

      return extended_fields_replacement_params_hash(:item_key => item_key, :item_class => item_class, :extra_fields => extra_fields )
    end

  end
end
