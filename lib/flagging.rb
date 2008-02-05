module Flagging
  unless included_modules.include? Flagging
    attr_accessor :do_not_moderate
    attr_accessor :pending_version

    def self.included(klass)
      klass.send :after_save, :do_moderation
      klass.extend(ClassMethods)
    end

    def flag_live_version_with(flag, message = nil)
      just_flagged_version = flag_at_with(self.version, flag, message)
      revert_to_latest_unflagged_version_or_create_blank_version
      just_flagged_version
    end

    def flag_at_with(version_number, flag, message = nil)
      # we tag the version with the flag passed
      version = self.versions.find_by_version(version_number)
      version.tag_list.add(flag)
      version.save_tags

      # if the user entered a message to do with the flag
      # update the tagging with it
      if !message.blank?
        tagging = version.taggings.find_by_tag_id(Tag.find_by_name(flag))
        tagging.message = message
        tagging.save
      end

      version
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

    def reject_this(version_number, message = nil)
      remove_pending_flag(version_number)
      flag_at_with(version_number, REJECTED_FLAG, message)
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
          break if last_version_number == 0

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

    def notify_moderators_immediatelly_if_necessary(options = { })
      if FREQUENCY_OF_MODERATION_EMAIL.is_a?(String) and FREQUENCY_OF_MODERATION_EMAIL == 'instant'
        # if histor_url is blank it will be figured out in view
        history_url = !options[:history_url].blank? ? options[:history_url] : nil

        message = !options[:message].blank? ? options[:message] : nil

        # specified user or default admin user
        flagging_user = !options[:flagging_user].blank? ? options[:flagging_user] : User.find(1)

        self.basket.moderators_or_next_in_line.each do |moderator|
          # url is handled in the view if blank
          UserNotifier.deliver_item_flagged_for(moderator,
                                                history_url,
                                                options[:flag],
                                                flagging_user,
                                                options[:submitter],
                                                options[:version],
                                                message)
        end
      end
    end

    def do_notifications_if_pending(version, submitter)
      # make sure the version is flagged as pending
      version = self.versions.find_by_version(version)

      if version.tags.include?(Tag.find_by_name(PENDING_FLAG))
        # notify user and moderators that a revision is pending review
        UserNotifier.deliver_pending_review_for(version.version, submitter)

        # if instant moderator notifcation
        notify_moderators_immediatelly_if_necessary(:flag => PENDING_FLAG,
                                                    :version => version.version,
                                                    :submitter => submitter)
      end
    end

    protected
    def do_moderation
      # if are we are using full moderation
      # where everything has to approved by an admin
      # before being seen in the basket
      # flag the submitted revision
      # which will have the side effect
      # of either staying at the last unflagged version
      # or
      # adding a blank revision, if no unflagged version is available
      if self.fully_moderated? and !self.do_not_moderate? and !self.already_at_blank_version?
        flag_live_version_with(PENDING_FLAG)
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
