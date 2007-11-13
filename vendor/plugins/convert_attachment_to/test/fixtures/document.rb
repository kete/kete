class Document < ActiveRecord::Base
  # we require attachment_fu setup
  has_attachment :storage => :file_system,
  :content_type => "['application/msword', 'application/pdf', 'text/html', 'text/plain']", :processor => :none

  # since testing doesn't really write files, just override to point at existing test files
  def full_filename(thumbnail = nil)
    file_system_path = "vendor/plugins/convert_attachment_to/test/fixtures/files"
    logger.debug("what is full_filename" + File.join(RAILS_ROOT, file_system_path, thumbnail_name_for(thumbnail)))
    File.join(RAILS_ROOT, file_system_path, thumbnail_name_for(thumbnail))
  end
end

class DocumentToHtml < Document
  # now our setup
  convert_attachment_to :html, :description
end

class DocumentToText < Document
  # now our setup
  convert_attachment_to :text, :description
end
