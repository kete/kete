class Import < ActiveRecord::Base
  IMPORTS_DIR = RAILS_ROOT + '/imports/'
  VALID_ARCHIVE_CLASSES = ['StillImage', 'AudioRecording', 'Video', 'Document']

  belongs_to :basket
  belongs_to :topic_type
  # user is the person that added as the creator of items imported
  belongs_to :user

  has_one :import_archive_file, :dependent => :destroy

  acts_as_licensed

  validates_presence_of :xml_type, :interval_between_records
  # don't allow special characters in directory name that will break our import
  validates_format_of :directory, :with => /^[^ \'\"<>\&,\/\\\?]*$/, :message => ": spaces and  \', \\, /, &, \", ?, <, and > characters aren't allowed"
  validates_numericality_of :interval_between_records, :only_integer => true, :message => "the interval must be in seconds"

end
