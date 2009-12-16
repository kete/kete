class AudioRecording < ActiveRecord::Base
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  # handles file uploads
  # we'll want to adjust the filename to include "...-1..." for each
  # version where "-1" is dash-version number
  # for images this will include thumbnails
  # this will require overriding full_filename method locally
  # TODO: add more content_types
  # processor none means we don't have to load expensive image manipulation
  # dependencies that we don't need
  # :file_system_path => "#{BASE_PRIVATE_PATH}/#{self.table_name}",
  # will rework with when we get to public/private split
  has_attachment :storage => :file_system, :file_system_path => "audio",
  :content_type => AUDIO_CONTENT_TYPES, :processor => :none,
  :max_size => MAXIMUM_UPLOADED_FILE_SIZE

  validates_as_attachment

  # Private Item mixin
  include ItemPrivacy::All

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  # Do not version self.file_private
  self.non_versioned_columns << "file_private"
  self.non_versioned_columns << "private_version_serialized"

  after_save :store_correct_versions_after_save

  # overriding full_filename to handle our customizations
  # TODO: is this thumbnail arg necessary for classes without thumbnails?
  # def full_filename(thumbnail = nil)
    # file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path].to_s
    # this is how this currently reads
    # rails_root/private/audio_recordings/recording_id/filename
    # TODO: we'll want to make it like this when we add kete (basket) scoping
    # rails_root/private/kete_path_name/audio_recordings/recording_id/filename
    # File.join(RAILS_ROOT, file_system_path, attachment_path_id, thumbnail_name_for(thumbnail))
  # end

  include HandleLegacyAttachmentFuPaths

  # custom error message, probably overkill
  # validates the size and content_type attributes according to the current model's options
  def attachment_attributes_valid?
    [:size, :content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      unless enum.nil? || enum.include?(send(attr_name))
        errors.add attr_name, I18n.t("audio_recording_model.not_acceptable_#{attr_name}",
                                     :max_size => (MAXIMUM_UPLOADED_FILE_SIZE / 1.megabyte))
      end
    end
  end

  include Embedded if ENABLE_EMBEDDED_SUPPORT
end
