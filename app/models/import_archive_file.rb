# for small imports, we allow zip, tar, and gzip files to be uploaded
class ImportArchiveFile < ActiveRecord::Base
  belongs_to :import

  # import archive happen to be the same content types as theme archives.
  has_attachment :storage => :file_system,
  :content_type => ACCEPTABLE_THEME_CONTENT_TYPES, :processor => :none,
  :max_size => MAXIMUM_UPLOADED_FILE_SIZE

  validates_as_attachment

  include ArchiveUtilities

  after_attachment_saved { |record| record.decompress_under(::Import::IMPORTS_DIR + record.import.directory)}

end
