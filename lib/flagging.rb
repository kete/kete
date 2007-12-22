module Flagging
  unless included_modules.include? Flagging
    attr_accessor :do_not_moderate

    def self.included(klass)
      klass.send :after_save, :do_moderation
      klass.extend(ClassMethods)
    end

    def flag_live_version_with(flag)
      just_flagged_version = flag_at_with(self.version, flag)
      revert_to_latest_unflagged_version_or_create_blank_version
      just_flagged_version
    end

    def flag_at_with(version_number, flag)
      # we tag the version with the flag passed
      version = self.versions.find_by_version(version_number)
      version.tag_list.add(flag)
      version.save_tags
      return version
    end

    def clear_flags_for(version)
      version.tag_list = nil
      version.save_tags
    end

    # not used, kept for reference
    def approve_this(version_number)
      version = self.versions.find_by_version(version_number)
      revert_to_version!(version)
      clear_flags_for(version)
    end

    def remove_pending_flag(version_number)
      version = self.versions.find_by_version(version_number)
      version.tag_list.remove(PENDING_FLAG)
      version.save_tags
    end

    def change_pending_to_reviewed_flag(version_number)
      remove_pending_flag(version_number)
      flag_at_with(version_number, REVIEWED_FLAG)
    end

    def reject_this(version_number)
      remove_pending_flag(version_number)
      flag_at_with(version_number, REJECTED_FLAG)
    end

    def max_version
      return 1 if new_record?
      (versions.calculate(:max, :version) || 0)
    end

    def revert_to_latest_unflagged_version_or_create_blank_version
      last_version_number = self.max_version

      logger.debug("what is last_version_number: " + last_version_number.to_s)

      last_version = self.versions.find_by_version(last_version_number)

      last_version_tags_count = last_version.tags.size
      if last_version_number > 1
        while last_version_tags_count > 0
          last_version_number = last_version_number - 1
          last_version = self.versions.find_by_version(last_version_number)
          last_version_tags_count = last_version.tags.size
        end
      end

      # prevents recursive moderating
      # from happening at the next save
      # which is triggered by either revert
      # or update to blank version below
      self.do_not_moderate = true

      # if there isn't a unflagged version, we create a new blank one
      # that states that the item is pending
      # and return that version
      if last_version_tags_count == 0
        revert_to_version! last_version
      elsif
        # we leave required fields alone
        # and let the view handle whether they should be shown
        update_hash = { :title => BLANK_TITLE,
          :description => nil,
          :extended_content => nil,
          :tag_list => nil }

        update_hash[:short_summary] = nil if self.can_have_short_summary?

        update_attributes(update_hash)
        add_as_contributor(User.find(:first))
      end
      reload
    end

    def flagged_version_user(version_number)
      self.contributions.find_by_version(version_number).user
    end

    def revert_to_version!(version_number)
      revert_to!(version_number)
      tag_list = self.raw_tag_list
      save_tags
    end

    def already_at_blank_version?
      title == BLANK_TITLE and description.nil? and extended_content.nil? and (!self.can_have_short_summary? or short_summary.nil?)
    end

    def fully_moderated?
      basket.fully_moderated?
    end

    def disputed?
      already_at_blank_version? or versions.last.tags.size > 0
    end

    def reverted?
      already_at_blank_version? or version != self.versions.last.version
    end

    def do_not_moderate?
      do_not_moderate.nil? ? false : do_not_moderate
    end

    protected
    def do_moderation
      # if are we are using full moderation
      # where everything has to approved by an admin
      # before being seen in the basket
      # flag the first revision
      # which will have the side effect
      # of adding a blank revision
      if self.fully_moderated? and !self.do_not_moderate? and !self.already_at_blank_version?
        # have to do this before the flagging happens
        # user_to_notify = flagged_version_user(self.version)

        flag_live_version_with(PENDING_FLAG)

        # TODO: put in notification
      end
    end
  end

  module ClassMethods
    def find_flagged
      not_applicable_tags = Tag.find(:all,
                                     :conditions => ["name in (?)",
                                                     [REVIEWED_FLAG, BLANK_FLAG]])
      table_name = base_class.name.tableize
      versions_table_name = self.versioned_table_name
      class_fk = self.versioned_foreign_key
      full_version_class_name = base_class.name + '::' + self.versioned_class_name

      select = " #{table_name}.*, #{versions_table_name}.title as version_title, max(#{versions_table_name}.version) as latest_version, tags.name as flag, taggings.created_at as flagged_at, taggings.message"

      joins = "JOIN #{versions_table_name} ON #{versions_table_name}.#{class_fk} = #{table_name}.id "
      joins += "JOIN taggings ON taggings.taggable_id = #{versions_table_name}.id AND taggings.taggable_type = '#{full_version_class_name}' "
      joins += "JOIN tags ON tags.id = taggings.tag_id"

      find_options = {
        :select => select,
        :joins => joins,
        :order => 'flagged_at desc',
        :group => "#{versions_table_name}.#{class_fk}" }

      if !not_applicable_tags.blank?
        find_options[:conditions] = ["tags.id not in (:not_applicable_tags)",
                                     { :not_applicable_tags => not_applicable_tags }]
      end

      find(:all, find_options)
    end

    def find_disputed
      find_flagged.select(&:disputed?)
    end
  end
end
