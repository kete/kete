module KeteFlaggingMethods
  # ROB:  The existing special-flagging (public/pending/etc) in kete is going to be removed.
  # 			this is a place to stick any code for working with theses.
  #
  #       Right now these are my best guesses for tests. I have no idea if they actually work. 
  #
  #       There's more information on flags used, moderation, etc, in the comments at the top 
  #       of flagging.rb.

	def pending?
		if is_a?(Comment)
			title != SystemSetting.blank_title
		else
			title != SystemSetting.blank_title || description != nil 	# is not null
		end
	end

	def public?
		if is_a?(Comment)
			title != SystemSetting.blank_title && title != SystemSetting.no_public_version_title && commentable_private == false
    else
			title != SystemSetting.blank_title && title != SystemSetting.no_public_version_title
    end
	end

	def private?
		if is_a?(Comment)
      title != SystemSetting.blank_title && commentable_private == true
    else
      title != SystemSetting.blank_title && private_version_serialized != nil 	# NOT NULL
    end
  end

  def disputed?
    tags.size > 0 && tags.join(',') !~ /(\#{already_moderated_flags.join('|')})/
  end

  def reviewed?
    tags.size > 0 && tags.join(',') =~ /(\#{SystemSetting.reviewed_flag})/
  end

  def rejected?
    tags.size > 0 && tags.join(',') =~ /(\#{SystemSetting.rejected_flag})/
  end
end