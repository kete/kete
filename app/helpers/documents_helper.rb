module DocumentsHelper
  def ok_to_convert_to_description?(document)
    ENABLE_CONVERTING_DOCUMENTS && Katipo::Acts::ConvertAttachmentTo.acceptable_content_types.include?(document.content_type)
  end
end
