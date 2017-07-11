# for small imports, we allow zip, tar, and gzip files to be uploaded
class ImportArchiveFile < ActiveRecord::Base
  belongs_to :import

  # import archive happen to be the same content types as theme archives.
  has_attachment storage: :file_system,
                 content_type: ACCEPTABLE_THEME_CONTENT_TYPES, 
                 processor: :none,
                 max_size: SystemSetting.maximum_uploaded_file_size,
                 file_system_path: "#{BASE_PRIVATE_PATH}/#{table_name}"

  validates_as_attachment

  # making directory structure for attachments handle larger number of attachments
  def partitioned_path(*args)
    # changed from %08d to %012d to be extra safe
    ('%012d' % attachment_path_id).scan(/..../) + args
  end

  include ArchiveUtilities

  set_callback :after_attachment_saved, :after do |record| 
    record.decompress_under(::Import::IMPORTS_DIR + record.import.directory)
  end
end
