include ActionController::UrlWriter
include ZoomControllerHelpers

module Flagging
  unless included_modules.include? Flagging
    attr_accessor :do_not_moderate
    attr_accessor :pending_version

    def self.included(klass)
      klass.send :after_save, :do_moderation

      # Each version has various statuses. Add conveniant checks for these.
      # We have to add these in this method because we need access to klass
      Module.class_eval("#{klass.name}::Version").class_eval <<-RUBY
        attr_accessor :flagged_at # we store this versions most recent flagged date

        def disputed?
          undisputed_flags = [REVIEWED_FLAG, REJECTED_FLAG, RESTRICTED_FLAG]
          tags.size > 0 && tags.join(',') !~ /(\#{undisputed_flags.join('|')})/
        end

        def reviewed?
          tags.size > 0 && tags.join(',') =~ /(\#{REVIEWED_FLAG})/
        end

        def rejected?
          tags.size > 0 && tags.join(',') =~ /(\#{REJECTED_FLAG})/
        end

        def disputed_flags
          undisputed_flags = [REVIEWED_FLAG, REJECTED_FLAG, RESTRICTED_FLAG]
          flags.select { |flag| !undisputed_flags.include?(flag.name) }
        end
      RUBY

      klass.extend(ClassMethods)
    end

    def flag_live_version_with(flag, message = nil)

      # Keep track if we're working with a public or private version
      show_serialized = self.respond_to?(:private) && self.private?

      # Do the flagging and reversion
      just_flagged_version = flag_at_with(self.version, flag, message)
      revert_to_latest_unflagged_version_or_create_blank_version

      # Return the private version if we were working with it before..
      show_serialized && !self.private? ? self.private_version! : self
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
        tagging.context = "flags"
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

      # Make sure version in the model is public
      store_correct_versions_after_save if self.respond_to?(:store_correct_versions_after_save)
    end

    def remove_pending_flag(version_number)
      version = self.versions.find_by_version(version_number)
      version.tag_list.remove(PENDING_FLAG)
      version.save_tags
    end

    # all moderator actions flags (reviewed, rejected, etc)
    # not user action (incorrect, duplicate etc)
    def remove_all_flags(version_number)
      version = self.versions.find_by_version(version_number)
      version.tag_list.remove(BLANK_FLAG)
      version.tag_list.remove(PENDING_FLAG)
      version.tag_list.remove(REVIEWED_FLAG)
      version.tag_list.remove(REJECTED_FLAG)
      version.tag_list.remove(RESTRICTED_FLAG)
      version.save_tags
    end

    def strip_flags_and_mark_reviewed(version_number)
      remove_all_flags(version_number)
      flag_at_with(version_number, REVIEWED_FLAG)
    end

    def review_this(version_number, options = {})
      remove_all_flags(version_number)
      flag_at_with(version_number, REVIEWED_FLAG, options[:message])
      flag_at_with(version_number, RESTRICTED_FLAG, options[:message]) if options[:restricted]
    end

    def reject_this(version_number, options = {})
      remove_all_flags(version_number)
      flag_at_with(version_number, REJECTED_FLAG, options[:message])
      flag_at_with(version_number, RESTRICTED_FLAG, options[:message]) if options[:restricted]
    end

    def max_version
      return 1 if new_record?
      (versions.calculate(:max, :version) || 0)
    end

    def latest_unflagged_version_with_condition(&block)
      last_version_number = self.max_version

      last_version = self.versions.find_by_version(last_version_number)
      last_version_tags_count = last_version.tags.size

      if last_version_number > 1
        while last_version_tags_count > 0 || !block.call(last_version)
          last_version_number = last_version_number - 1
          break if last_version_number == 0

          last_version = self.versions.find_by_version(last_version_number)
          last_version_tags_count = last_version.tags.size
        end
      end

      # Only return a valid result
      if last_version_tags_count == 0 && block.call(last_version)
        last_version
      else
        nil
      end
    end

    # James Stradling <james@katipo.co.nz> - 2008-05-05
    # Updated to handle private and public items
    def revert_to_latest_unflagged_version_or_create_blank_version
      last_version_number = self.max_version

      logger.debug("what is last_version_number: " + last_version_number.to_s)

      last_version = self.versions.find_by_version(last_version_number)
      last_version_tags_count = last_version.tags.size

      if last_version_number > 1
        while last_version_tags_count > 0 || ( last_version.respond_to?(:private) && last_version.private? != self.private? )
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
      if last_version_tags_count == 0 && ( !last_version.respond_to?(:private?) || last_version.private? == self.private? )

        if last_version.respond_to?(:private?) && last_version.private?

          # If the version if private, store instead of reverting.
          revert_to(last_version)

          # No, doing this will cause duplicate versions.
          # save_without_revision
          # store_correct_versions_after_save
        else
          revert_to_version! last_version
        end
      else
        # we leave required fields alone
        # and let the view handle whether they should be shown
        update_hash = { :title => BLANK_TITLE,
          :description => nil,
          :extended_content => nil,
          :tag_list => nil }

        update_hash[:private] = self.private? if self.respond_to?(:private)
        update_hash[:description] = PENDING_FLAG if self.class.name == 'Comment'

        update_hash[:short_summary] = nil if self.can_have_short_summary?

        if respond_to?(:without_saving_private)
          without_saving_private do
            update_attributes!(update_hash)
          end
        else
          update_attributes!(update_hash)
        end

        add_as_contributor(User.find(:first), self.version)

      end

      # Ensure we store the latest private version and load a public one if applicable.
      store_correct_versions_after_save if respond_to?(:store_correct_versions_after_save)
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
      title == BLANK_TITLE and (description.nil? or (self.class.name == 'Comment' and description == PENDING_FLAG)) and extended_content.nil? and (!self.can_have_short_summary? or short_summary.nil?)
    end

    def fully_moderated?
      basket.fully_moderated? && (basket.settings[:moderated_except].blank? || !basket.settings[:moderated_except].include?(self.class.name))
    end

    def disputed?
      already_at_blank_version? or latest_version_of_this_privacy.tags.size > 0
    end

    def disputed_or_not_available?
      already_at_blank_version? or
        latest_version_of_this_privacy.tags.size > 0 or
        at_placeholder_public_version?
    end

    def latest_version_of_this_privacy
      versions.sort { |a, b| b.id <=> a.id }.find { |v| !v.respond_to?(:private?) || v.private? == private? }
    end

    def reverted?
      already_at_blank_version? or version != self.versions.last.version
    end

    def do_not_moderate?
      do_not_moderate.nil? ? false : do_not_moderate
    end

    def at_placeholder_public_version?
      title == NO_PUBLIC_VERSION_TITLE
    end

    def notify_moderators_immediatelly_if_necessary(options = { })
      if FREQUENCY_OF_MODERATION_EMAIL.is_a?(String) and FREQUENCY_OF_MODERATION_EMAIL == 'instant'
        # if histor_url is blank it will be figured out in view
        history_url = if !options[:history_url].blank?
          options[:history_url]
        else
          url_for(:urlified_name => basket.urlified_name,
                  :controller => zoom_class_controller(self.class.name),
                  :action => 'history', :id => self, :locale => false)
        end

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

        self.reload # make sure we have the latest attribute values (specifically version)
        if should_moderate?
          flag_live_version_with(PENDING_FLAG)
        end

      end

      def should_moderate?
        self.fully_moderated? and
          !self.do_not_moderate? and
          !self.already_at_blank_version? and
          !self.at_placeholder_public_version?
      end

  end

  module ClassMethods

    # Returns a collection of item versions that have been flagged one way or another
    # use find_(disputed/reviewed/rejected) rather than this method directly
    def find_flagged(basket_id)
      full_version_class_name = base_class.name + '::' + self.versioned_class_name

      flaggings = Tagging.all(
        :include => [:tag, { :taggable => [:flags] }],
        :conditions => {
          :basket_id => basket_id,
          :context => 'flags',
          :taggable_type => full_version_class_name
        }
      )

      flaggings.collect do |flagging|
        flagged_item = flagging.taggable
        flagged_item.flagged_at = flagging.created_at
        flagged_item
      end.uniq
    end

    # find_disputed(basket_id)
    # find_reviewed(basket_id)
    # find_rejected(basket_id)
    %w{ disputed reviewed rejected }.each do |type|
      define_method("find_#{type}") do |basket_id|
        find_flagged(basket_id).select(&:"#{type}?")
      end
    end

    def find_non_pending(type = :all, conditions_string = String.new)
      if conditions_string.blank?
        conditions_string = "title != :pending_title"
        conditions_string += " or description is not null" if name != 'Comment'
      end
      find(type, :conditions => [conditions_string, { :pending_title => BLANK_TITLE }])
    end

    def find_all_public_non_pending
      find_non_pending(:all, PUBLIC_CONDITIONS)
    end

    def find_all_non_pending
      find_non_pending
    end

  end
end
