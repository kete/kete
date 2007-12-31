class Document < ActiveRecord::Base
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
  # TODO: needs some of the new filetypes like openoffice, pages, plenty of old ones, too
  has_attachment :storage => :file_system,
  :content_type => DOCUMENT_CONTENT_TYPES, :processor => :none,
  :max_size => MAXIMUM_UPLOADED_FILE_SIZE

  validates_as_attachment

  # overriding full_filename to handle our customizations
  # TODO: is this thumbnail arg necessary for classes without thumbnails?
  # def full_filename(thumbnail = nil)
    # file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path].to_s
    # this is how this currently reads
    # rails_root/private/documents/recording_id/filename
    # TODO: we'll want to make it like this when we add kete (basket) scoping
    # rails_root/private/kete_path_name/documents/recording_id/filename
    # File.join(RAILS_ROOT, file_system_path, attachment_path_id, thumbnail_name_for(thumbnail))
  # end

  include HandleLegacyAttachmentFuPaths

  # this supports auto populated description
  # attribute with converted pdfs, msword docs,
  # html, and plain text
  # requires that a number of things be installed
  # to support it, so wrapping it in a system setting
  # also, we manage when the conversion happens
  # rather than having it use a callback
  if ENABLE_CONVERTING_DOCUMENTS
    convert_attachment_to :output_type => :html, :target_attribute => :description, :run_after_save => false
  end

  def attachment_attributes_valid?
    [:size, :content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      errors.add attr_name, 'is not acceptable. It should be a .pdf, .doc, or other document file.' unless enum.nil? || enum.include?(send(attr_name))
    end
  end

  # probably won't work on Windoze
  # good thing we don't officially support it!
  def decompress_as_theme
    target_dir = THEMES_ROOT + '/'
    case content_type
    when 'application/zip'
      `unzip #{self.full_filename} -d #{target_dir}`
    when 'application/x-gtar'
      `tar xf #{self.full_filename} #{target_dir}`
    when 'application/x-gzip'
      if !self.filename.scan("tgz").blank? or !self.filename.scan("tar\.gz").blank?
        `tar xfz #{self.full_filename} -C #{target_dir}`
      else
        `cp #{self.full_filename} #{target_dir}; cd #{target_dir}; gunzip #{self.filename}`
      end
    end
  end

  def could_be_new_theme?
    return false unless ['application/zip', 'application/x-gtar', 'application/x-gzip'].include?(self.content_type)
    likely_theme_name = File.basename(self.filename, File.extname(self.filename))
    Dir.new(THEMES_ROOT).each do |listing|
      return false if listing == likely_theme_name
    end
    true
  end
end
