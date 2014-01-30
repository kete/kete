module OverrideAttachmentFuMethods
  def partitioned_path(*args)
    # Overrides partitioned_path defined in attachment_fu

    # changed from %08d to %012d to be extra safe
    # avoiding directory naming collisions with legacy directories
    ("%012d" % attachment_path_id).scan(/..../) + args

    # ROB: attachment path had a legacy version for systems that didn't upgrade
    #      their file-system organisation:  [attachment_path_id.to_s] + args
  end

  def public_filename
    # ROB: Override the link attachment link method provided by attachment_fu
    # so that we can point to valid content when using the Kete Horowhenua database (which 
    # assumes Horowhenua content files).
    # Setting attachments_overide_url in the environment/* files applies this.

    if Rails.configuration.attachments_overide_url
      relative_link = fix_attachment_fu_links( super() )
      "#{Rails.configuration.attachments_overide_url}#{relative_link}"
    else
      super
    end
  end

  def fix_attachment_fu_links(relative_link)
    # ROB: At a seemingly random point (roughly around mid July 2007) the attachments 
    # returned by attachment_fu's public_filename() change from 
    #   e.g. /images/0000/0004/9312/charles_st_medium.jpg 
    # to 
    #   e.g. /49312/charles_st_medium.jpg
    # This isn't followed by the pothoven-attachment_fu gem we're using so we have to
    # fix it manually.

    if self.class == ImageFile && still_image.id < 9320
      capture_numbers_and_filename = %r{/image_files/(\d*)/(\d*)/(\d*)/(.*)}
      capture_numbers_and_filename.match(relative_link)
      numbers_without_zeros = "#{$1}#{$2}#{$3}".to_i

      "/image_files/#{numbers_without_zeros}/#{$4}"

    elsif self.class == AudioRecording && id < 29
      capture_numbers_and_filename = %r{/audio/(\d*)/(\d*)/(\d*)/(.*)}
      capture_numbers_and_filename.match(relative_link)
      numbers_without_zeros = "#{$1}#{$2}#{$3}".to_i

      "/audio/#{numbers_without_zeros}/#{$4}"

    elsif self.class == Video && id < 16
      capture_numbers_and_filename = %r{/video/(\d*)/(\d*)/(\d*)/(.*)}
      capture_numbers_and_filename.match(relative_link)
      numbers_without_zeros = "#{$1}#{$2}#{$3}".to_i

      "/video/#{numbers_without_zeros}/#{$4}"

    elsif self.class == Document && id < 643
      capture_numbers_and_filename = %r{/documents/(\d*)/(\d*)/(\d*)/(.*)}
      capture_numbers_and_filename.match(relative_link)
      numbers_without_zeros = "#{$1}#{$2}#{$3}".to_i

      "/documents/#{numbers_without_zeros}/#{$4}"

    else
      relative_link
    end
  end
end



