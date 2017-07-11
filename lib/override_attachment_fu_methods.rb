module OverrideAttachmentFuMethods
  # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu/backends/file_system_backend.rb#L47
  def partitioned_path(*args)
    # Overrides partitioned_path defined in attachment_fu

    # changed from %08d to %012d to be extra safe
    # avoiding directory naming collisions with legacy directories
    ('%012d' % attachment_path_id).scan(/..../) + args

    # ROB: attachment path had a legacy version for systems that didn't upgrade
    #      their file-system organisation:  [attachment_path_id.to_s] + args
  end

  # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu/backends/file_system_backend.rb#L71
  def public_filename
    # ROB: Override the link attachment link method provided by attachment_fu
    # so that we can point to valid content when using the Kete Horowhenua database (which
    # assumes Horowhenua content files).
    # Setting attachments_overide_url in the environment/* files applies this.

    if Rails.configuration.respond_to? :attachments_overide_url
      relative_link = fix_attachment_fu_links(super())
      "#{Rails.configuration.attachments_overide_url}#{relative_link}"
    else
      super
    end
  end

  private

  # not in attachment_fu
  def fix_attachment_fu_links(relative_link)
    # ROB: At a seemingly random point (roughly around mid July 2007) the attachments
    # returned by attachment_fu's public_filename() change from
    #   e.g. /images/0000/0004/9312/charles_st_medium.jpg
    # to
    #   e.g. /images/49312/charles_st_medium.jpg
    # This isn't followed by the pothoven-attachment_fu gem we're using so we have to
    # fix it manually.
    #
    # This method uses ids from the Horowhenau database (found by trial and
    # error) - this code will not work in general case.

    if self.class == ImageFile && still_image.id < 9320
      apply_attachment_fu_link_fix(relative_link)

    elsif self.class == AudioRecording && id < 29
      apply_attachment_fu_link_fix(relative_link)

    elsif self.class == Video && id < 16
      apply_attachment_fu_link_fix(relative_link)

    elsif self.class == Document && id < 643
      apply_attachment_fu_link_fix(relative_link)

    else
      relative_link
    end
  end

  # not in attachment_fu
  def apply_attachment_fu_link_fix(relative_link)
    capture_numbers_and_filename = %r{/(\w*)/(\d*)/(\d*)/(\d*)/(.*)}
    capture_numbers_and_filename.match(relative_link)

    ci_type_name = $1
    numbers_without_zeros = "#{$2}#{$3}#{$4}".to_i
    filename = $5

    "/#{ci_type_name}/#{numbers_without_zeros}/#{filename}"
  end
end
