module PrivacyControlsHelper
  
  def file_private_radio_options(item)
    if !item.new_record? && item.file_private? === false
      { "disabled" => "disabled" }
    else
      Hash.new
    end
  end
  
  def privacy_controls_description
    "Note: Individual versions of this item can be public or private. The latest public version will be shown to non-basket members if available.  Otherwise, this item is completely private."
  end
  
end