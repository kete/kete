class WebLink < ActiveRecord::Base

  include PgSearch
  include PgSearchCustomisations
  multisearchable against: [
    :title,
    :description,
    :url,
    :raw_tag_list,
    :searchable_extended_content_values
  ]

  # Common configuration
  # ####################
  # * all the common configuration is handled by this module
  # * it creates the required instance methods for acts_as_licensed
  include ConfigureAsKeteContentItem

  # Tweak the versioning that was configured in the line above
  self.non_versioned_columns << "file_private"
  self.non_versioned_columns << "private_version_serialized"

  # Setup attributes 
  # ################

  # some web sites will always refuse our url requests
  # allow the user to say that the url is definitely valid
  attr_accessor :force_url

  validates_presence_of :url
  validates_uniqueness_of :url, case_sensitive: false

  # validates_http_url comes from a separate gem
  validates_http_url :url, :if => Proc.new { |web_link| web_link.new_record? && !web_link.force_url }
  
  # ItemPrivacy::All
  # * adds method overrides for:
  #   * acts_as_versioned
  #   * attachment_fu
  #   * acts-as-taggable-on
  include ItemPrivacy::All
  
  # acts as licensed but this is not versionable (we cannot change a license
  # once it is applied)
  acts_as_licensed

  # * defined in ItemPrivacy::All
  after_save :store_correct_versions_after_save
end
