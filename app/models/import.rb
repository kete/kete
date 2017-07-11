class Import < ActiveRecord::Base
  IMPORTS_DIR = Rails.root + '/imports/'
  VALID_ARCHIVE_CLASSES = ATTACHABLE_CLASSES

  belongs_to :basket
  belongs_to :topic_type
  belongs_to :related_topic_type, class_name: 'TopicType'
  belongs_to :extended_field_that_contains_record_identifier, class_name: 'ExtendedField'
  belongs_to :extended_field_that_contains_related_topics_reference, class_name: 'ExtendedField'
  # user is the person that added as the creator of items imported
  belongs_to :user

  has_one :import_archive_file, dependent: :destroy

  acts_as_licensed

  validates_presence_of :xml_type, :interval_between_records
  # don't allow special characters in directory name that will break our import
  validates_format_of :directory, with: /^[^ \'\"<>\&,\/\\\?]*$/, message: lambda { I18n.t('import_model.invalid_chars', invalid_chars: "spaces and  \', \\, /, &, \", ?, <, and >") }
  validates_numericality_of :interval_between_records, only_integer: true, message: lambda { I18n.t('import_model.must_be_seconds') }

  # HACK -- directory appears to have become a reserved word in some context
  # and as a result is a private method
  def directory_name
    attributes['directory']
  end
end
