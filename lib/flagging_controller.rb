# frozen_string_literal: true

module FlaggingController
  unless included_modules.include? FlaggingController
    # set up our helper methods
    def self.included(klass)
      klass.helper_method :can_preview?
    end

    # user or moderater can add message with flagging
    def flag_form
      @flag = params[:flag]
      @form_target =
        case @flag
        when SystemSetting.rejected_flag
          'reject'
        when SystemSetting.reviewed_flag
          'review'
        else
          'flag_version'
                            end

      # use one form template for all controllers
      render template: 'topics/flag_form'
    end

    def flag_version
      setup_flagging_vars

      # Revert to the passed in version if applicable
      @item.revert_to(params[:version]) if !params[:version].blank?

      # we tag the current version with the flag passed
      # and revert to an unflagged version
      # or create a blank unflagged version if necessary
      flagged_version = @item.flag_live_version_with(@flag, @message)

      # Reload to public version so zoom code works as expected
      @item.reload

      raise 'We are not on public version' if @item.respond_to?(:private) && @item.private?

      flagging_clear_caches_and_update_zoom(@item)

      @item.notify_moderators_immediatelly_if_necessary(
        flag: @flag,
        history_url: history_url(@item),
        flagging_user: @current_user,
        version: @version,
        submitter: @submitter,
        message: @message
      )

      flash[:notice] = I18n.t('flagging_controller_lib.flag_version.item_flagged')
      redirect_to @item_url
    end

    def flagging_clear_caches_and_update_zoom(item)
      # add contributor and update zoom if needed
      after_successful_zoom_item_update(item, @version_after_update)
    end

    # permission check in controller
    # reverts to version
    # and removes flags on that version
    def restore
      setup_flagging_vars

      current_version = @item.version

      # unlike flag_version, we create a new version
      # so we track the restore in our version history
      @item.revert_to(@version)

      @item.send(:allow_nil_values_for_extended_content=, false)

      if not @item.valid?

        # James - 2009-01-16
        # If the version we're restoring to is invalid, then the moderator must improve the content
        # to make it valid before restoring the version.
        name_for_params = @item.class.table_name.singularize
        instance_variable_set("@#{name_for_params}", @item)
        @editing = true

        # We need topic types for editing a topic
        @topic_types = @topic.topic_type.full_set if @item.is_a?(Topic)

        # Set the version comment
        params[name_for_params.to_sym] = {}
        params[name_for_params.to_sym][:version_comment] = I18n.t(
          'flagging_controller_lib.restore.version_comment',
          version: @version
        )

        # Exempt the next version from moderation
        # See app/controllers/application.rb lines 241 through 282
        exempt_next_version_from_moderation!(@item)

        flash[:notice] = I18n.t('flagging_controller_lib.restore.missing_details')
        render action: 'edit'

        @item.send(:allow_nil_values_for_extended_content=, true)

      else

        # if version we are about to supersede
        # is blank, flag it as blank for clarity in the history
        # this doesn't do the reversion in itself
        @item.flag_at_with(current_version, SystemSetting.blank_flag) if @item.already_at_blank_version?

        @item.tag_list = @item.raw_tag_list
        @item.version_comment = I18n.t(
          'flagging_controller_lib.restore.version_comment',
          version: @version
        )
        @item.do_not_moderate = true

        versions_before_save = @item.versions.size

        if @item.respond_to?(:save_without_saving_private!)
          @item.save_without_saving_private!
        else
          @item.save!
        end

        # If the version is not what we expect, there may have been a race condition.
        logger.debug "Race condition during restore. Version expected to be #{versions_before_save + 1} but was #{@item.version}." unless @item.version == versions_before_save + 1

        # keep track of the moderator's contribution
        @item.add_as_contributor(@current_user)

        # now that this item is approved by moderator
        # we get rid of pending flag
        # then flag it as reviewed
        @item.strip_flags_and_mark_reviewed(@version)

        # Return to latest public version before changing flags..
        @item.send :store_correct_versions_after_save if @item.respond_to?(:store_correct_versions_after_save)

        flagging_clear_caches_and_update_zoom(@item)

        approval_message = I18n.t(
          'flagging_controller_lib.restore.made_live',
          site_name: SystemSetting.pretty_site_name,
          basket_name: @current_basket.name
        )

        # notify the contributor of this revision
        UserNotifier.deliver_approval_of(
          @version,
          @item_url,
          @submitter,
          approval_message
        )

        flash[:notice] = I18n.t(
          'flagging_controller_lib.restore.approved',
          zoom_class: zoom_class_humanize(@item.class.name)
        )

        redirect_to @item_url
      end
    end

    # for cases where a version is flagged, decided to be ok, and the mod
    # doesn't want to make this the live version (restore) or reject it.
    def review
      setup_flagging_vars

      @item.review_this(
        @version, message: @message,
                  restricted: params[:restricted].present?
      )

      # notify the contributor of this revision
      UserNotifier.deliver_reviewing_of(
        @version,
        correct_url_for(@item, @version),
        @submitter,
        @message
      )

      flash[:notice] = I18n.t(
        'flagging_controller_lib.review.reviewed',
        zoom_class: zoom_class_humanize(@item.class.name)
      )

      redirect_to @item_url
    end

    def reject
      setup_flagging_vars

      @item.reject_this(
        @version, message: @message,
                  restricted: params[:restricted].present?
      )

      # notify the contributor of this revision
      UserNotifier.deliver_rejection_of(
        @version,
        correct_url_for(@item, @version),
        @submitter,
        @message
      )

      flash[:notice] = I18n.t(
        'flagging_controller_lib.reject.rejected',
        zoom_class: zoom_class_humanize(@item.class.name)
      )

      redirect_to @item_url
    end

    # view history of edits to an item
    # including each version's flags
    # this expects a rhtml template within each controller's view directory
    # so that different types of items can have their history display customized
    def history
      @item = item_from_controller_and_id

      # Only show private versions to authorized people.
      if permitted_to_view_private_items?
        @versions = @item.versions
      else
        @versions = @item.versions.reject { |v| v.respond_to?(:private) and v.private? }
        @show_private_versions_notice = (@versions.size != @item.versions.size)
      end

      @current_public_version = @item.version

      @item.private_version do
        @current_private_version = @item.version
      end if @item.respond_to?(:private_version)

      if @item.contributors.empty?
        @item_contributors = []
      else
        @item_contributors = @item.contributors.all
      end

      @contributor_index = 0

      @item_taggings = Hash.new
      taggings = Tagging.all(conditions: ["taggable_type = ? AND taggable_id IN (?) AND context = 'flags'", "#{@item.class.name}::Version", @versions])
      taggings.each do |tagging|
        @item_taggings[tagging[:taggable_id]] ||= Array.new
        @item_taggings[tagging[:taggable_id]] << tagging.tag
      end

      @users = Hash.new

      # one template (with logic) for all controllers
      render template: 'topics/history'
    end

    # preview a version of an item
    # assumes a preview templates under the controller
    def preview
      setup_flagging_vars

      # no need to preview live version
      if @item.version.to_s == @version
        redirect_to correct_url_for(@item)
      else
        @creator = @item.creator
        @last_contributor = @submitter || @creator
        @preview_version = @item.versions.find_by_version(@version)
        @flags = Array.new
        @flag_messages = Array.new
        @preview_version.taggings.each do |tagging|
          @flags << tagging.tag.name
          @flag_messages << tagging.message if !tagging.message.blank?
        end
        @item.revert_to(@preview_version)

        # Do not allow access to restricted or private item versions..
        if (@flags.include?(SystemSetting.restricted_flag) && !@at_least_moderator) ||
           (@item.respond_to?(:private?) && @item.private? && !permitted_to_view_private_items?)
          raise ActiveRecord::RecordNotFound
        end

        # one template (with logic) for all controllers
        render template: 'topics/preview'
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = I18n.t(
        'flagging_controller_lib.preview.no_public',
        controller: params[:controller].singularize
      )
      redirect_to controller: 'account', action: 'login'
    end

    def can_preview?(options = {})
      submitter = options[:submitter] || options[:item].submitter_of(options[:version_number])
      @at_least_a_moderator or @current_user == submitter or !@current_basket.fully_moderated?
    end

    private
    def setup_flagging_vars
      @item = item_from_controller_and_id
      @flag = !params[:flag].blank? ? params[:flag] : nil
      @version = !params[:version].blank? ? params[:version] : @item.version
      @version_after_update = @item.max_version + 1
      if !params[:message].blank? && !params[:message][0].blank?
        @message = params[:message][0]
      else
        @message = String.new
      end
      @item_url = correct_url_for(@item)
      @submitter = @item.submitter_of(@version) if !@version.nil?
    end
  end
end
