class Import < ActiveRecord::Base
  IMPORTS_DIR = RAILS_ROOT + '/imports/'
  belongs_to :basket
  belongs_to :topic_type
  # user is the person that added as the creator of items imported
  belongs_to :user

  validates_presence_of :directory, :xml_type
  # don't allow special characters in directory name that will break our import
  validates_format_of :directory, :with => /^[^ \'\"<>\&,\/\\\?]*$/, :message => ": spaces and  \', \\, /, &, \", ?, <, and > characters aren't allowed"

  private
  def validate
    errors.add_to_base("Folder not found. The folder must exist in the proper place for the import to proceed.") unless File.directory?(IMPORTS_DIR + directory)
  end
end
