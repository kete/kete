class Document < ActiveRecord::Base

  include PgSearch
  include PgSearchCustomisations
  multisearchable against: [
    :title,
    :description,
    :raw_tag_list,
    :short_summary,
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
  # TODO: needs some of the new filetypes like openoffice, pages, plenty of old ones, too
  has_attachment    storage: :file_system,
                    content_type: SystemSetting.document_content_types,
                    processor: :none,
                    max_size: SystemSetting.maximum_uploaded_file_size

  # Private Item mixin
  include ItemPrivacy::All

  # Do not version self.file_private
  non_versioned_columns << 'file_private'
  non_versioned_columns << 'private_version_serialized'

  def self.updated_since(date)
    # Document.where( <Document or its join tables is newer than date>  )

    documents =                       ::Document.arel_table
    taggings =                        Tagging.arel_table
    contributions =                   Contribution.arel_table
    content_item_relations =          ContentItemRelation.arel_table
    deleted_content_item_relations =  Arel::Table.new(:deleted_content_item_relations)


    join_table = ::Document.outer_joins(:taggings).
                            outer_joins(:contributions).
                            outer_joins(:content_item_relations).
                            joins('LEFT OUTER JOIN  deleted_content_item_relations ' +
                                  'ON deleted_content_item_relations.related_item_id = documents.id ' +
                                  "AND deleted_content_item_relations.related_item_type = 'Document'")

    result = join_table.where(
      documents[:updated_at].gt(date).
      or( taggings[:created_at].gt(date) ). # Tagging doesn't have a updated_at column.
      or( contributions[:updated_at].gt(date) ).
      or( content_item_relations[:updated_at].gt(date) ).
      or( deleted_content_item_relations[:updated_at].gt(date) )
    )

    result.uniq   # Joins give us repeated results
  end

  after_save :store_correct_versions_after_save

  validates_as_attachment

  include OverrideAttachmentFuMethods

  # this supports auto populated description
  # attribute with converted pdfs, msword docs,
  # html, and plain text
  # requires that a number of things be installed
  # to support it, so wrapping it in a system setting
  # also, we manage when the conversion happens
  # rather than having it use a callback
  if SystemSetting.enable_converting_documents
    convert_attachment_to output_type: :html, target_attribute: :description, run_after_save: false
  end

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  def attachment_attributes_valid?
    [:size, :content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      if attr_name.to_s == 'content_type' && !enum.blank?
        logger.debug("what is received #{attr_name}: " + send(attr_name).inspect)
      end
      unless enum.nil? || enum.include?(send(attr_name))
        errors.add attr_name, I18n.t("document_model.not_acceptable_#{attr_name}",
                                     max_size: (SystemSetting.maximum_uploaded_file_size / 1.megabyte))
      end
    end
  end

  include ArchiveUtilities

  # take gzip, zip, or tar file and decompress it to public/themes
  def decompress_as_theme
    decompress_under(THEMES_ROOT + '/')
  end

  def could_be_new_theme?
    # must be supporting in our decompression utilities
    return false unless ACCEPTABLE_THEME_CONTENT_TYPES.include?(content_type)
    # skip, if a directory already exists in public/themes
    return false if Dir.entries(THEMES_ROOT).include?(File.basename(filename, File.extname(filename)))
    true
  end

  include Embedded if SystemSetting.enable_embedded_support
end
