# frozen_string_literal: true

class WebLink < ActiveRecord::Base
  include PgSearch
  include PgSearchCustomisations
  multisearchable against: %i[
    title
    description
    url
    raw_tag_list
    searchable_extended_content_values
  ]

  # Common configuration
  # ####################
  # * all the common configuration is handled by this module
  # * it creates the required instance methods for acts_as_licensed
  include ConfigureAsKeteContentItem

  # Tweak the versioning that was configured in the line above
  non_versioned_columns << 'file_private'
  non_versioned_columns << 'private_version_serialized'

  def self.updated_since(date)
    # WebLink.where( <WebLink or its join tables is newer than date>  )

    web_links =                       WebLink.arel_table
    taggings =                        Tagging.arel_table
    contributions =                   Contribution.arel_table
    content_item_relations =          ContentItemRelation.arel_table
    deleted_content_item_relations =  Arel::Table.new(:deleted_content_item_relations)

    join_table = WebLink.outer_joins(:taggings)
                        .outer_joins(:contributions)
                        .outer_joins(:content_item_relations)
                        .joins('LEFT OUTER JOIN  deleted_content_item_relations ' +
                               'ON deleted_content_item_relations.related_item_id = web_links.id ' +
                               "AND deleted_content_item_relations.related_item_type = 'WebLink'")

    result = join_table.where(
      web_links[:updated_at].gt(date)
      .or(taggings[:created_at].gt(date)) # Tagging doesn't have a updated_at column.
      .or(contributions[:updated_at].gt(date))
      .or(content_item_relations[:updated_at].gt(date))
      .or(deleted_content_item_relations[:updated_at].gt(date))
    )

    result.uniq # Joins give us repeated results
  end

  # Setup attributes
  # ################

  # some web sites will always refuse our url requests
  # allow the user to say that the url is definitely valid
  attr_accessor :force_url

  validates_presence_of :url
  validates_uniqueness_of :url, case_sensitive: false

  validates_url :url, if: Proc.new { |web_link| web_link.new_record? && !web_link.force_url }

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
