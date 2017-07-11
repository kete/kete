# James Stradling <james@katipo.co.nz>
# 2008-04-15

# Item Privacy Modification

# RABID:
# to implement privacy, we need to tweak the versioning, tagging, attachment subsystems
# all those tweaks happen in this file
# The methods defined in this file are added to ActiveModel models
# - it is not clean which of those methods shadow methods in the gems that provide versioning, tagging, attachments

module ItemPrivacy

  module All

    def self.included(klass)
      klass.class_eval do
        include ActsAsVersionedOverload::InstanceMethods
        extend  ActsAsVersionedOverload::ClassMethods
        include AttachmentFuOverload
        include TaggingOverload::InstanceMethods
        extend TaggingOverload::SingletonMethods
      end
    end

  end

  module ActsAsVersionedOverload

    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods

      # TODO: Work out how to invoke an instance method from an included module..
      # Might need to overload self.non_versioned_columns the method
      # self.non_versioned_columns << "file_private"

      # Find the latest public version of the current item
      # Find the latest version of the current item
      # def latest_version
      #   raise "DEPRECATED: latest_version"
      #   versions.last
      # end

      # EOIN: call load_private! and recover from (and ignore) any & all exceptions that it might throw
      def private_version!
        load_private!
      rescue
        nil
      end

      # EOIN: call load_public! and recover from (and ignore) any & all exceptions that it might throw
      def public_version!
        load_public!
      rescue
        nil
      end

      # Checks if at some point someone created a public version of this item
      # Uses method in flagging.rb lib to determine that (if the title is the default
      # "No public version available", the only private versions exist)
      def has_public_version?
        # EOIN: it seems this code has a dependency on the flagging code
        !at_placeholder_public_version?
      end

      # EOIN: if the model has 'private' and 'private_version_serialized'
      # attributes and the private_version_serialized is NOT empty, then we
      # can infer that this model has a private version
      # EOIN: this implies that to have a private version, you must have something in 'private_version_serialized'
      def has_private_version?
        respond_to?(:private?) && respond_to?(:private_version_serialized) && !private_version_serialized.blank?
      end

      def latest_version_is_private?
        # skip versions that are simply placeholders,
        # i.e. the only public version is "no public version"

        # EOIN: "find the most recently created row in the versions table where the title is not 'no public version'"
        # EOIN: there seems to be something special about the "no public version" title ???
        # EOIN: this seems to rely on id's sequentially increasing as new rows are added to the table. Is that wise?
        last_version = versions.find(:first,
                                     conditions: "title != \'#{SystemSetting.no_public_version_title}\'",
                                     order: 'id DESC')

        # EOIN: if the last version has a boolean attribute named 'private' and that attribute is set to true, then return true. Otherwise return false
        last_version.respond_to?(:private?) && last_version.private?
      end

      def private_version(&block)
        private_version!
        result = block.call
        reload

        # Return the result of the block, not the reloaded item
        result
      end

      # * if the model has a "private" boolean attribute, rails will create a #private? method for it
      # * method summary:
      #   "if the model has a private attribute and that attribute is set to true, then return true, otherwise return false"
      def is_private?
        respond_to?(:private) && private?
      end

      # "save the model to DB but skip the store_correct_versions_after_save method callback"
      def save_without_saving_private!
        without_saving_private do
          save!
        end
      end

      # EOIN: what does protected mean from an included module?
      protected

        def latest_public_version
          version = latest_unflagged_version_with_condition do |v|
            !v.private?
          end
        end

        # ROB:  From what I can see this function:
        #       * if is private?:  stashes the model's values, loads the last public version,
        #         then re-applies the old private-version's id (strangely).
        #       * if is public but has private-version:  gets the private version and then
        #         updates it's id to the public-version's id
        # EOIN:
        # * #save_without_saving_private! saves the model but skips this method
        # * this is hooked up as an after_save callback directly in the model class file
        #   which implies that not all models that include this module will want this method as a callback
        def store_correct_versions_after_save
          if private?
            store_private!

            # Store the basket id from the private version for future use..
            private_basket_id = basket_id

            load_public!

            # James - 2008-12-08
            # Ensure we keep the public verion of the item in sync if the basket of the private
            # version has changed.
            update_attribute(:basket_id, private_basket_id) if basket_id != private_basket_id

          elsif has_private_version?

            # Ensure we keep the private version of the item in sync as well..
            public_basket_id = basket_id

            private_version do
              update_attribute(:basket_id, public_basket_id) if basket_id != public_basket_id
            end

          end

          ## Always return true to avoid halting the filter chain
          true
        end

        # Using Marshall as..
        # YAML is 34.65 times slower in serialization and 5.66 times slower in unserialization.
        # http://significantbits.wordpress.com/2008/01/29/yaml-vs-marshal-performance/
        #
        # ROB:  store_private! loops through the columns set to be versioned and creates a array
        #       of name-value tuples. These are converted to YAML and stashed in the a variable
        #       which is STORED ON THE IN-MEMORY MODEL (ie not in the database).
        def store_private!(save_after_serialization = false)

          prepared_array = self.class.versioned_columns.inject(Array.new) do |memo, k|
            memo << [k.name, send(k.name.to_sym)]
          end

          # Also save the current version into the private version column
          prepared_array << ['version', version]

          # Save the prepared array into the attribute column..
          without_revision do
            without_saving_private do
              self.private_version_serialized = YAML.dump(prepared_array)
              save!
            end
          end

        end

        # Load the saved private attributes into the current instance.
        #
        # ROB:  load_private: loads the information stashed on the IN-MEMORY MODEL by
        #       store_private! and applies these to the model's active-record variables.
        def load_private!
          # EOIN:reload the current model from the DB, presumably this makes sure we have the most recent version of it
          reload

          # EOIN: => private_version_serialized contains YAML
          private_attrs = YAML.load(private_version_serialized)

          # EOIN: private_version_serialized contains an Array
          raise 'No private attributes' if private_attrs.nil? || !private_attrs.kind_of?(Array)

          # EOIN: private_version_serialized contains an Array of 2-tuples (Array with two values)
          private_attrs.each do |key, value|
            # EOIN: create a attribute writer for each element of the private_version_serialized array
            send("#{key}=".to_sym, value)
          end

          self
        end

        # Revert to the most recent public version and save.
        # We do this after_save via store_correct_versions_after_save in order to keep
        # the latest public version in the 'master' model record.
        def load_public!
          if public_version = latest_public_version
            without_saving_private do
              revert_to!(public_version)
            end

            # At this point, I know from testing that the reverted version
            # and current model are public and appropriate.
          else

            # EOIN: it seems like update_hash is a default set of attributes tha
            update_hash = {
              title: SystemSetting.no_public_version_title,
              description: SystemSetting.no_public_version_description,
              extended_content: nil,
              tag_list: nil,
              private: false,
              basket_id: basket_id
            }

            update_hash[:short_summary] = nil if can_have_short_summary?

            # Update without callbacks
            # EOIN: this also saves the record in the DB
            update_attributes!(update_hash)

            # EOIN: this seems to assume that the first user in the DB will be the admin. This seems dangerous ???
            add_as_contributor(User.find(:first))
          end

          reload
        # rescue
        #   false
        end

        # EOIN:
        # * this instance method just passes the call on to the class method with the same name
        # * the class method is implemented below
        def without_saving_private(&block)
          self.class.without_saving_private(&block)
        end

    end

    module ClassMethods

      # replace the store_correct_versions_after_save method with an empty one
      # then run the given block
      # then re-enable the original store_correct_versions_after_save method
      # "run the given block but skip the store_correct_versions_after_save method callback"
      def without_saving_private(&block)
        class_eval do
          alias_method :orig_store_correct_versions_after_save, :store_correct_versions_after_save
          alias_method :store_correct_versions_after_save, :empty_callback
        end
        block.call
      ensure
        class_eval do
          alias_method :store_correct_versions_after_save, :orig_store_correct_versions_after_save
        end
      end

    end

  end

  module TaggingOverload

    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
        extend SingletonMethods
      end
    end

    module InstanceMethods

      # Transparently map tags for the current item to the tags of the correct privacy
      def tags
        order_tags(private? ? private_tags : public_tags)
      end

      def tag_list
        private? ? private_tag_list : public_tag_list
      end

      def tag_list=(new_tags)
        if private?
          self.private_tag_list = new_tags
        else
          self.public_tag_list = new_tags
        end
      end

      private

      def order_tags(tags_out_of_order)
        return tags_out_of_order if raw_tag_list.blank?

        # Get the raw tag list, split, squish (removed whitespace), and add each to raw_tag_array
        # Make sure we skip if the array already has that tag name (remove any duplicates that occur)
        raw_tag_array = Array.new
        raw_tag_list.split(',').each do |raw_tag|
          next if raw_tag_array.include?(raw_tag.squish)
          raw_tag_array << raw_tag.squish
        end

        tags = Array.new
        if tags_out_of_order.size > 0
          # resort them to match raw_tag_list order
          tags = tags_out_of_order.sort { |a, b| raw_tag_array.index(a.name).to_i <=> raw_tag_array.index(b.name).to_i }
        end
        tags
      end

    end

    module SingletonMethods

      # Required by tag cloud functionality on basket home-pages.
      def tag_counts(options, private_tags=false)

        # Only return public tags (for the time being..)
        tags = Hash.new
        tags[:public] = public_tag_counts(options)
        tags[:private] = private_tags ? private_tag_counts(options) : {}
        tags
      end

    end

  end

  module AttachmentFuOverload

    # Not in attachment_fu
    attr_accessor :force_privacy

    # Not in attachment_fu
    def file_private=(*args)
      # File privacy can only go private => public as a public file cannot
      # be made private at a later time due to the need for previous
      # versions have file access.
      unless !force_privacy && file_private === false
        @old_filename ||= full_filename unless !respond_to?(:filename) || filename.nil?
        super(*args)
      end
    end

    # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu/backends/file_system_backend.rb#L21
    # * Override the AttachmentFu default method to ensure we place the
    #   attachment in the correct folder.
    def full_filename(thumbnail = nil)
      file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:path_prefix].to_s.gsub('public', '')
      File.join(Rails.root, attachment_path_prefix, file_system_path, *partitioned_path(thumbnail_name_for(thumbnail)))
    end

    # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu/backends/file_system_backend.rb#L27
    # * Make sure that the correct base path is stripped off in
    #   AttachmentFu::Backends::FileSystemBackend.public_filename
    def base_path
      @base_path ||= File.join(Rails.root, attachment_path_prefix)
    end

    private

      # Not in attachment_fu
      # * Get the path we should be using based on the item's privacy
      def attachment_path_prefix
        file_private? ? 'private' : 'public'
      end

      # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu/backends/file_system_backend.rb#L97
      # * Renames the given file before saving
      def rename_file
        return unless @old_filename && @old_filename != full_filename
        if save_attachment? && File.exists?(@old_filename)
          FileUtils.rm @old_filename
        elsif File.exists?(@old_filename)

          # Ensure there a folder to move the file into
          FileUtils.mkdir_p(File.dirname(full_filename))
          FileUtils.mv @old_filename, full_filename

          # Remove the directory we moved from too if it's empty
          Dir.rmdir(File.dirname(@old_filename)) if (Dir.entries(File.dirname(@old_filename))-['.', '..']).empty?
        end
        @old_filename =  nil
        true
      end

  end

end
