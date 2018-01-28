# RABID:
# * this module is
#   * included directly in Topic,
#   * included by ConfigureAsKeteContentItem into every class that it is included in
#     * AudioRecording
#     * Comment
#     * Document
#     * StillImage
#     * Video
#     * WebLink
# * it adds the ClassMethods module to the class and a bunch of stuff into the instance
# * it adds an after_save callback that invokes moderation
# * it adds 3 attributes to the instances
# 1. do_not_moderate
# 2. pending_version
# 3. flagged_at
# * it adds some methods to the {FOO}::Version class

# This module seems to be responsible for
# Flagging seems to be used in Kete to do
#   * moderation
#   * review

# Moderation
# ==========
# * moderation is implemented by saving particular tags with the model
# * moderation also has to be aware of the various older versions of the model

# flags that can be set on a model (as tags):
# * blank
# * pending
#     * whether a model is "pending" or not seems to depend on the contents of it's title and description attribute too - see #find_non_pending below
# * reviewed
#     * can save an option message with the flag
# * rejected

# * restricted

# the following flags are inferred by the state of other flags
# * disputed

# when a model has been moderated, it has one of the following values:
#     [0] "reviewed by moderator",
#     [1] "rejected",
#     [2] "restricted",
#     [3] "used for moderation"

# * Tags are not just used for moderation - users can set their own tags on models for search etc.

# Kete sets up 2 tag contexts for it's models
# 1. public_tags
# 2. private_tags

# It adds a further tag context to the MyModel::Version models
# 3. flags

# Admins can click on 'moderate contents' for a basket and then be presented with links that do
# * "make live"
# * "mark as reviewed"
# * "reject"

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
          tags.size > 0 && tags.join(',') !~ /(\#{already_moderated_flags.join('|')})/
        end

        def reviewed?
          tags.size > 0 && tags.join(',') =~ /(\#{SystemSetting.reviewed_flag})/
        end

        def rejected?
          tags.size > 0 && tags.join(',') =~ /(\#{SystemSetting.rejected_flag})/
        end

        def already_moderated_flags
          #{klass.name}.already_moderated_flags
        end

        def disputed_flags
          flags.select { |flag| !already_moderated_flags.include?(flag.name) }
        end
      RUBY

      klass.extend(ClassMethods)
    end

    def flag_live_version_with(flag, message = nil)
      # Keep track if we're working with a public or private version
      show_serialized = respond_to?(:private) && private?

      # Do the flagging and reversion
      just_flagged_version = flag_at_with(version, flag, message)
      revert_to_latest_unflagged_version_or_create_blank_version

      # Return the private version if we were working with it before..
      # EOIN & ROB: this return value is broken logic but it seems like it is ignored by the caller anyway
      show_serialized && !private? ? private_version! : self
    end

    def flag_at_with(version_number, flag, message = nil)
      # we tag the version with the flag passed
      version = versions.find_by_version(version_number)
      version.tag_list.add(flag)
      version.save_tags

      # if the user entered a message to do with the flag
      # update the tagging with it
      if !message.blank?
        tagging = version.taggings.find_by_tag_id(Tag.find_by_name(flag))
        tagging.message = message
        tagging.context = 'flags'
        tagging.save
      end

      version
    end

    def clear_flags_for(version)
      version.tag_list = nil
      version.save_tags
    end

    # not used, kept for reference
    # def approve_this(version_number)
    #   version = self.versions.find_by_version(version_number)
    #   revert_to_version!(version)
    #   clear_flags_for(version)

    #   # Make sure version in the model is public
    #   store_correct_versions_after_save if self.respond_to?(:store_correct_versions_after_save)
    # end

    def remove_pending_flag(version_number)
      version = versions.find_by_version(version_number)
      version.tag_list.remove(SystemSetting.pending_flag)
      version.save_tags
    end

    # all moderator actions flags (reviewed, rejected, etc)
    # not user action (incorrect, duplicate etc)
    def remove_all_flags(version_number)
      version = versions.find_by_version(version_number)
      version.tag_list.remove(SystemSetting.blank_flag)
      version.tag_list.remove(SystemSetting.pending_flag)
      version.tag_list.remove(SystemSetting.reviewed_flag)
      version.tag_list.remove(SystemSetting.rejected_flag)
      version.tag_list.remove(SystemSetting.restricted_flag)
      version.save_tags
    end

    def strip_flags_and_mark_reviewed(version_number)
      remove_all_flags(version_number)
      flag_at_with(version_number, SystemSetting.reviewed_flag)
    end

    def review_this(version_number, options = {})
      remove_all_flags(version_number)
      flag_at_with(version_number, SystemSetting.reviewed_flag, options[:message])
      flag_at_with(version_number, SystemSetting.restricted_flag, options[:message]) if options[:restricted]
    end

    def reject_this(version_number, options = {})
      remove_all_flags(version_number)
      flag_at_with(version_number, SystemSetting.rejected_flag, options[:message])
      flag_at_with(version_number, SystemSetting.restricted_flag, options[:message]) if options[:restricted]
    end

    def max_version
      return 1 if new_record?
      (versions.calculate(:maximum, :version) || 0)
    end

    def latest_unflagged_version_with_condition(&block)
      last_version_number = max_version

      last_version = versions.find_by_version(last_version_number)
      last_version_tags_count = last_version.tags.size

      if last_version_number > 1
        while last_version_tags_count > 0 || !block.call(last_version)
          last_version_number = last_version_number - 1
          break if last_version_number == 0

          last_version = versions.find_by_version(last_version_number)
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
      last_version_number = max_version

      logger.debug('what is last_version_number: ' + last_version_number.to_s)

      last_version = versions.find_by_version(last_version_number)
      last_version_tags_count = last_version.tags.size

      if last_version_number > 1
        while last_version_tags_count > 0 || (last_version.respond_to?(:private) && last_version.private? != private?)
          last_version_number = last_version_number - 1
          break if last_version_number == 0

          last_version = versions.find_by_version(last_version_number)
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
      if last_version_tags_count == 0 && (!last_version.respond_to?(:private?) || last_version.private? == private?)

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
        update_hash = { title: SystemSetting.blank_title,
                        description: nil,
                        extended_content: nil,
                        tag_list: nil }

        update_hash[:private] = private? if respond_to?(:private)
        update_hash[:description] = SystemSetting.pending_flag if self.class.name == 'Comment'

        update_hash[:short_summary] = nil if can_have_short_summary?

        if respond_to?(:without_saving_private)
          without_saving_private do
            update_attributes!(update_hash)
          end
        else
          update_attributes!(update_hash)
        end

        add_as_contributor(User.find(:first), version)

      end

      # Ensure we store the latest private version and load a public one if applicable.
      store_correct_versions_after_save if respond_to?(:store_correct_versions_after_save)
      reload
    end

    def flagged_version_user(version_number)
      contributions.find_by_version(version_number).user
    end

    def revert_to_version!(version_number)
      revert_to!(version_number)
      tag_list = raw_tag_list
      save_tags
    end

    def already_at_blank_version?
      title == SystemSetting.blank_title and (description.nil? or (self.class.name == 'Comment' and description == SystemSetting.pending_flag)) and extended_content.nil? and (!can_have_short_summary? or short_summary.nil?)
    end

    def fully_moderated?
      basket.fully_moderated? && (basket.setting(:moderated_except).blank? || !basket.setting(:moderated_except).include?(self.class.name))
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
      already_at_blank_version? or version != versions.last.version
    end

    def do_not_moderate?
      do_not_moderate.nil? ? false : do_not_moderate
    end

    def at_placeholder_public_version?
      title == SystemSetting.no_public_version_title
    end

    def notify_moderators_immediatelly_if_necessary(options = {})
      if SystemSetting.frequency_of_moderation_email.is_a?(String) and SystemSetting.frequency_of_moderation_email == 'instant'
        # if histor_url is blank it will be figured out in view
        history_url = if !options[:history_url].blank?
                        options[:history_url]
                      else
                        url_for(host: SystemSetting.site_name,
                                urlified_name: basket.urlified_name,
                                controller: zoom_class_controller(self.class.name),
                                action: 'history', id: self, locale: false)
                      end

        message = !options[:message].blank? ? options[:message] : nil

        # specified user or default admin user
        flagging_user = !options[:flagging_user].blank? ? options[:flagging_user] : User.find(1)

        basket.moderators_or_next_in_line.each do |moderator|
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
      version = versions.find_by_version(version)

      if version.tags.include?(Tag.find_by_name(SystemSetting.pending_flag))
        # notify user and moderators that a revision is pending review
        UserNotifier.deliver_pending_review_for(version.version, submitter)

        # if instant moderator notifcation
        notify_moderators_immediatelly_if_necessary(flag: SystemSetting.pending_flag,
                                                    version: version.version,
                                                    submitter: submitter)
      end
    end

    # EOIN: I do not know what the purpose of making these methods protected is.
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

      reload # make sure we have the latest attribute values (specifically version)
      if should_moderate?
        flag_live_version_with(SystemSetting.pending_flag)
      end
    end

    def should_moderate?
      fully_moderated? and
        !do_not_moderate? and
        !already_at_blank_version? and
        !at_placeholder_public_version?
    end

  end

  module ClassMethods
    def already_moderated_flags
      [SystemSetting.reviewed_flag, SystemSetting.rejected_flag, SystemSetting.restricted_flag, SystemSetting.blank_flag]
    end

    # Returns a collection of item versions that have been flagged one way or another
    # use find_(disputed/reviewed/rejected) rather than this method directly
    def find_flagged(basket_id, flagging_type = nil)
      full_version_class_name = base_class.name + '::' + versioned_class_name

      conditions = {
        basket_id: basket_id,
        context: 'flags',
        taggable_type: full_version_class_name
      }

      case flagging_type
      when 'disputed'
        already_moderated_flag_ids = Tag.find_all_by_name(already_moderated_flags).collect { |f| f.id }

        # only change conditions if there are tagging instances of already_moderated_flags
        # otherwise all taggings that are flags are disputed
        if already_moderated_flag_ids.size > 0
          # have to do a more complex set of conditions to get "tag_id not in" into the where clause
          conditions_sql_array = conditions.keys.collect { |k| "#{k} = :#{k}" }
          conditions_sql = conditions_sql_array.join(' AND ')
          conditions_sql += " AND tag_id not in (#{already_moderated_flag_ids.join(',')})"
          conditions = [conditions_sql, conditions]
        end
      when 'reviewed', 'rejected'
        conditions[:tag_id] = Tag.find_by_name(Kete.send("#{flagging_type}_flag")).id
      end

      flaggings = Tagging.all(
        include: [:tag, { taggable: [:flags] }],
        conditions: conditions
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
    %w{disputed reviewed rejected}.each do |type|
      define_method("find_#{type}") do |basket_id|
        # the select with the predicate method covers versions
        # that have multiple flaggings on them
        find_flagged(basket_id, type).select(&:"#{type}?")
      end
    end

    def find_non_pending(type = :all, conditions_string = String.new)
      if conditions_string.blank?
        conditions_string = 'title != :pending_title'
        conditions_string += ' or description is not null' if name != 'Comment'
      end
      find(type, conditions: [conditions_string, { pending_title: SystemSetting.blank_title }])
    end

    def find_all_public_non_pending
      find_non_pending(:all, Kete.public_conditions)
    end

    def find_all_non_pending
      find_non_pending
    end
  end
end
