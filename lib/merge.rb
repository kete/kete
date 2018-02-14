module Merge
  unless included_modules.include? Merge
    # the last version listed will take precedence
    # in merging the values
    # i.e. if title exists and is different in all versions
    # passed in, the title from the last passed version
    # will be the final title in merged result
    # the same goes for extended fields
    # adjust your order of version numbers passed in accordingly
    # if only one version is specified, current version of item
    # is assumed as last version to merge
    def merge_values_from(*source_versions)
      starting_version = version

      if source_versions.size == 1 && source_versions[0] != starting_version
        source_versions << starting_version
      end

      if source_versions.size < 2
        raise 'You must specify at least one version other than current version.'
      end

      # get the attributes for the item that can be updated
      # and there existing values
      # prune attributes that shouldn't be messed with
      ok_to_update = %w[title short_summary description]

      attributes_to_update = Hash.new
      attributes.each do |k, v|
        next unless ok_to_update.include?(k)
        attributes_to_update[k] = v
      end

      # extended_content is a special case
      # since it contains nested values in xml
      # that are instantiated into virtual attributes
      structured_extended_content_thus_far = Hash.new

      # work through the versions' and accumulate values
      source_versions.each do |version_number|
        revert_to(version_number)
        version_attributes = attributes

        attributes_to_update.keys.each do |key|
          new_value = version_attributes[key]
          attributes_to_update[key] = new_value unless new_value.blank?
        end

        extended_values = structured_extended_content
        unless extended_values.blank?
          extended_values.each do |k, v|
            if (v.present? && !v.is_a?(Array)) ||
               (v.is_a?(Array) && v.present? && v.size > 0 && v.first.present?)

              structured_extended_content_thus_far[k] = v
            end
          end
        end
      end

      # now that we have merger of all versions' attributes
      # update them in place
      revert_to(starting_version)

      attributes_to_update.each do |k, v|
        send(k + '=', v)
      end

      unless structured_extended_content_thus_far.blank?
        self.structured_extended_content = structured_extended_content_thus_far
      end

      self
    end
  end
end
