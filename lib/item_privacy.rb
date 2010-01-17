# James Stradling <james@katipo.co.nz>
# 2008-04-15

# Item Privacy Modification

# include ItemPrivacy::All

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

      def private_version!
        load_private!
      rescue
        nil
      end

      def public_version!
        load_public!
      rescue
        nil
      end

      # Checks if at some point someone created a public version of this item
      # Uses method in flagging.rb lib to determine that (if the title is the default
      # "No public version available", the only private versions exist)
      def has_public_version?
        !self.at_placeholder_public_version?
      end

      def has_private_version?
        respond_to?(:private?) && respond_to?(:private_version_serialized) && !private_version_serialized.blank?
      end

      def latest_version_is_private?
        # skip versions that are simply placeholders,
        # i.e. the only public version is "no public version"
        last_version = versions.find(:first,
                                     :conditions => "title != \'#{NO_PUBLIC_VERSION_TITLE}\'",
                                     :order => 'id DESC')
        last_version.respond_to?(:private?) && last_version.private?
      end

      def private_version(&block)
        private_version!
        result = block.call
        reload

        # Return the result of the block, not the reloaded item
        result
      end

      def is_private?
        respond_to?(:private) && private?
      end

      def save_without_saving_private!
        without_saving_private do
          save!
        end
      end

      protected

        def latest_public_version
          version = latest_unflagged_version_with_condition do |v|
            !v.private?
          end
        end

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
        def store_private!(save_after_serialization = false)

          prepared_array = self.class.versioned_columns.inject(Array.new) do |memo, k|
            memo << [k.name, send(k.name.to_sym)]
          end

          # Also save the current version into the private version column
          prepared_array << ["version", version]

          # Save the prepared array into the attribute column..
          without_revision do
            without_saving_private do
              self.private_version_serialized = YAML.dump(prepared_array)
              save!
            end
          end

        end

        # Load the saved private attributes into the current instance.
        def load_private!
          reload
          private_attrs = YAML.load(private_version_serialized)
          raise "No private attributes" if private_attrs.nil? || !private_attrs.kind_of?(Array)

          private_attrs.each do |key, value|
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

            update_hash = {
              :title => NO_PUBLIC_VERSION_TITLE,
              :description => NO_PUBLIC_VERSION_DESCRIPTION,
              :extended_content => nil,
              :tag_list => nil,
              :private => false,
              :basket_id => basket_id
            }

            update_hash[:short_summary] = nil if can_have_short_summary?

            # Update without callbacks
            self.update_attributes!(update_hash)

            add_as_contributor(User.find(:first))
          end

          reload
        # rescue
        #   false
        end

        def without_saving_private(&block)
          self.class.without_saving_private(&block)
        end

    end

    module ClassMethods

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

    attr_accessor :force_privacy

    def file_private=(*args)

      # File privacy can only go private => public as a public file cannot
      # be made private at a later time due to the need for previous
      # versions have file access.
      unless !self.force_privacy && self.file_private === false
        @old_filename ||= full_filename unless !self.respond_to?(:filename) || filename.nil?
        super(*args)
      end
    end

    # Override the AttachmentFu default method to ensure we place the attachment
    # in the correct folder.
    def full_filename(thumbnail = nil)
      file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:path_prefix].to_s.gsub("public", "")
      File.join(RAILS_ROOT, attachment_path_prefix, file_system_path, *partitioned_path(thumbnail_name_for(thumbnail)))
    end

    # Make sure that the correct base path is stripped off in
    # AttachmentFu::Backends::FileSystemBackend.public_filename
    # Overridden from AttachmentFu
    def base_path
      @base_path ||= File.join(RAILS_ROOT, attachment_path_prefix)
    end

    private

      # Get the path we should be using based on the item's
      # privacy
      def attachment_path_prefix
        file_private? ? 'private' : 'public'
      end

      # Renames the given file before saving
      # Overridden from AttachmentFu
      def rename_file
        return unless @old_filename && @old_filename != full_filename
        if save_attachment? && File.exists?(@old_filename)
          FileUtils.rm @old_filename
        elsif File.exists?(@old_filename)

          # Ensure there a folder to move the file into
          FileUtils.mkdir_p(File.dirname(full_filename))
          FileUtils.mv @old_filename, full_filename

          # Remove the directory we moved from too if it's empty
          Dir.rmdir(File.dirname(@old_filename)) if (Dir.entries(File.dirname(@old_filename))-['.','..']).empty?
        end
        @old_filename =  nil
        true
      end

  end

end
