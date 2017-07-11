class Video < ActiveRecord::Base

  include PgSearch
  include PgSearchCustomisations
  multisearchable against: [
    :title,
    :description,
    :raw_tag_list,
    :searchable_extended_content_values
  ]

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
  has_attachment storage: :file_system, 
                 file_system_path: 'video', 
                 content_type: SystemSetting.video_content_types, 
                 processor: :none, 
                 max_size: SystemSetting.maximum_uploaded_file_size

  validates_as_attachment

  # Private Item mixin
  include ItemPrivacy::All

  # Do not version self.file_private
  non_versioned_columns << 'file_private'
  non_versioned_columns << 'private_version_serialized'

  def self.updated_since(date)
    # Video.where( <Video or its join tables is newer than date>  )

    videos =                          Video.arel_table
    taggings =                        Tagging.arel_table
    contributions =                   Contribution.arel_table
    content_item_relations =          ContentItemRelation.arel_table
    deleted_content_item_relations =  Arel::Table.new(:deleted_content_item_relations)


    join_table = Video.outer_joins(:taggings).
                       outer_joins(:contributions).
                       outer_joins(:content_item_relations).
                       joins('LEFT OUTER JOIN  deleted_content_item_relations ' +
                             'ON deleted_content_item_relations.related_item_id = videos.id ' +
                             "AND deleted_content_item_relations.related_item_type = 'Video'")

    result = join_table.where(
      videos[:updated_at].gt(date).
      or( taggings[:created_at].gt(date) ). # Tagging doesn't have a updated_at column.
      or( contributions[:updated_at].gt(date) ).
      or( content_item_relations[:updated_at].gt(date) ).
      or( deleted_content_item_relations[:updated_at].gt(date) )
    )

    result.uniq   # Joins give us repeated results
  end

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  # this callback is implemented in ItemPrivacy::All
  after_save :store_correct_versions_after_save

  # overriding full_filename to handle our customizations
  # TODO: is this thumbnail arg necessary for classes without thumbnails?
  # def full_filename(thumbnail = nil)
    # file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path].to_s
    # this is how this currently reads
    # rails_root/private/videos/recording_id/filename
    # TODO: we'll want to make it like this when we add kete (basket) scoping
    # rails_root/private/kete_path_name/videos/recording_id/filename
    # File.join(RAILS_ROOT, file_system_path, attachment_path_id, thumbnail_name_for(thumbnail))
  # end

  include OverrideAttachmentFuMethods

  def attachment_attributes_valid?
    [:size, :content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      unless enum.nil? || enum.include?(send(attr_name))
        errors.add attr_name, I18n.t("video_model.not_acceptable_#{attr_name}",
                                     max_size: (SystemSetting.maximum_uploaded_file_size / 1.megabyte))
      end
    end
  end

  include Embedded if SystemSetting.enable_embedded_support
end
