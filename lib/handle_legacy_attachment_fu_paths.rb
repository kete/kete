module HandleLegacyAttachmentFuPaths
  # this is where we handle contributed and created items by users
  unless included_modules.include? HandleLegacyAttachmentFuPaths
    # workaround for legacy attachments
    def partitioned_path(*args)
      legacy_count = nil
      case self.class.name
      when 'ImageFile'
        legacy_count = SystemSetting.legacy_imagefile_paths_up_to
      when 'Document'
        legacy_count = SystemSetting.legacy_document_paths_up_to
      when 'AudioRecording'
        legacy_count = SystemSetting.legacy_audiorecording_paths_up_to
      when 'Video'
        legacy_count = SystemSetting.legacy_video_paths_up_to
      end

      if legacy_count.nil? or attachment_path_id.to_i > legacy_count
        # changed from %08d to %012d to be extra safe
        # avoiding directory naming collisions with legacy directories
        ("%012d" % attachment_path_id).scan(/..../) + args
      else
        [attachment_path_id.to_s] + args
      end
    end
  end
end
