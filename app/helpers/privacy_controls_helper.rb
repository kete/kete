module PrivacyControlsHelper
  def file_private_radio_options(item)
    if !item.new_record? && item.file_private? === false
      { 'disabled' => 'disabled' }
    else
      {}
    end
  end

  def privacy_controls_description
    t('privacy_controls_helper.privacy_controls_description.public_vs_private')
  end
end
