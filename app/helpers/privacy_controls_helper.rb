module PrivacyControlsHelper
  
  def file_private_radio_options(item)
    if !item.new_record? && item.file_private? === false
      { "disabled" => "disabled" }
    else
      Hash.new
    end
  end
  
end