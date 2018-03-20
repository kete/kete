# frozen_string_literal: true

module DocumentsHelper
  def ok_to_convert_to_description?(document)
    SystemSetting.enable_converting_documents && Katipo::Acts::ConvertAttachmentTo.acceptable_content_types.include?(document.content_type)
  end
end
