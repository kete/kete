# frozen_string_literal: true

class AudioRecording < ActiveRecord::Base
  include PgSearch
  include PgSearchCustomisations
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem
  include ItemPrivacy::All # Private Item mixin
  include OverrideAttachmentFuMethods
  include Embedded if SystemSetting.enable_embedded_support

  multisearchable against: %i[
    title
    description
    raw_tag_list
    searchable_extended_content_values
  ]

  # handles file uploads
  # we'll want to adjust the filename to include "...-1..." for each
  # version where "-1" is dash-version number
  # for images this will include thumbnails
  # this will require overriding full_filename method locally
  # TODO: add more content_types
  # processor none means we don't have to load expensive image manipulation
  # dependencies that we don't need
  # file_system_path: "#{BASE_PRIVATE_PATH}/#{self.table_name}",
  # will rework with when we get to public/private split
  has_attachment storage: :file_system,
                 file_system_path: 'audio',
                 content_type: SystemSetting.audio_content_types,
                 processor: :none,
                 max_size: SystemSetting.maximum_uploaded_file_size

  # Validators
  validates_as_attachment

  # hooks
  after_save :store_correct_versions_after_save

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  # Do not version self.file_private
  non_versioned_columns << 'file_private'
  non_versioned_columns << 'private_version_serialized'

  def self.updated_since(date)
    # AudioRecording.where( <AudioRecording or its join tables is newer than date>  )

    audio_recordings =                AudioRecording.arel_table
    taggings =                        Tagging.arel_table
    contributions =                   Contribution.arel_table
    content_item_relations =          ContentItemRelation.arel_table
    deleted_content_item_relations =  Arel::Table.new(:deleted_content_item_relations)

    join_table = AudioRecording.outer_joins(:taggings)
                               .outer_joins(:contributions)
                               .outer_joins(:content_item_relations)
                               .joins('LEFT OUTER JOIN  deleted_content_item_relations ' \
                                      'ON deleted_content_item_relations.related_item_id = audio_recordings.id ' \
                                      "AND deleted_content_item_relations.related_item_type = 'AudioRecording'")

    result = join_table.where(
      audio_recordings[:updated_at].gt(date)
      .or(taggings[:created_at].gt(date)) # Tagging doesn't have a updated_at column.
      .or(contributions[:updated_at].gt(date))
      .or(content_item_relations[:updated_at].gt(date))
      .or(deleted_content_item_relations[:updated_at].gt(date))
    )

    result.uniq # Joins give us repeated results
  end

  # custom error message, probably overkill
  # validates the size and content_type attributes according to the current model's options
  def attachment_attributes_valid?
    %i[size content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      unless enum.nil? || enum.include?(send(attr_name))
        errors.add attr_name, I18n.t(
          "audio_recording_model.not_acceptable_#{attr_name}",
          max_size: (SystemSetting.maximum_uploaded_file_size / 1.megabyte)
        )
      end
    end
  end
end
