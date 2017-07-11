class StillImage < ActiveRecord::Base

  include PgSearch
  include PgSearchCustomisations
  multisearchable against: [
    :title,
    :description,
    :raw_tag_list,
    :searchable_extended_content_values
  ]

  # image files, including different sized versions of the original
  # are handled by ImageFile model
  has_many :image_files, dependent: :destroy
  has_one :original_file, conditions: 'parent_id is null', class_name: 'ImageFile'
  has_one :thumbnail_file, conditions: "parent_id is not null and thumbnail = 'small_sq'", class_name: 'ImageFile'

  # these correspond to sizes in image_file.rb
  SystemSetting.image_sizes.keys.each do |size|
    has_one "#{size.to_s}_file".to_sym, conditions: ['parent_id is not null and thumbnail = ?', size.to_s], class_name: 'ImageFile'
  end

  has_many :resized_image_files, conditions: 'parent_id is not null', class_name: 'ImageFile'

  # Each image can only belong to one User's portrait
  has_one :user_portrait_relation, dependent: :delete
  has_one :portrayed_user, through: :user_portrait_relation, source: :user

  # all the common configuration is handled by this module
  # Walter McGinnis, 2008-05-10
  # this has to go after image files for successful basket destroys
  # otherwise still_image_versions rows fail to delete because of order of foreign key constraints
  include ConfigureAsKeteContentItem

  # Private Item mixin
  include ItemPrivacy::All

  # Do not version self.file_private
  non_versioned_columns << 'file_private'
  non_versioned_columns << 'private_version_serialized'

  def self.updated_since(date)
    # StillImage.where( <StillImage or its join tables is newer than date>  )

    taggings_sql =                       Tagging.uniq.select(:taggable_id).where(taggable_type: 'StillImage').where('created_at > ?', date).to_sql
    contributions_sql =                  Contribution.uniq.select(:contributed_item_id).where(contributed_item_type: 'StillImage').where('updated_at > ?', date).to_sql
    content_item_relations_sql =         ContentItemRelation.uniq.select(:related_item_id).where(related_item_type: 'StillImage').where('updated_at > ?', date).to_sql
    deleted_content_item_relations_sql = "SELECT DISTINCT related_item_id FROM deleted_content_item_relations WHERE related_item_type = 'StillImage' AND updated_at > ?"

    and_query = StillImage.where('still_images.updated_at > ?', date).
                           where("still_images.id IN ( #{taggings_sql} )"). # Tagging doesn't have an updated_at column.
                           where("still_images.id IN ( #{contributions_sql} )").
                           where("still_images.id IN ( #{content_item_relations_sql} )").
                           where("still_images.id IN ( #{deleted_content_item_relations_sql} )", date)
                           # I would liked to have searched for changed ImageFiles too
                           # but the table doesnt have created_at/updated_at.

    or_query = and_query.where_values.join(' OR ')

    StillImage.where(or_query).uniq    # avoid repeated results from repeating ids.
  end

  def self.pre_load_associations
    # Speed up request with pre-loading of associations.
    includes(:creators).includes(:original_file).includes(:license).includes(:basket)
  end

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  after_save :store_correct_versions_after_save

  def self.find_with(size, still_image)
    find(still_image, include: "#{size}_file".to_sym)
  end

  after_update :update_image_file_locations

  def created_by?(user)
    (creator || contributors.first) == user
  end

  def is_portrait?
    user_portrait_relation
  end

# !! Re-enable on switch to rails 3.2:
#  include Embedded if SystemSetting.enable_embedded_support
#
#  # Walter McGinnis, 2011-02-15
#  # oEmbed Functionality
#  include OembedProvidable
#
#  oembed_options = Hash.new
#  OembedProvider.required_attributes[:photo].each do |key|
#    oembed_options[key] = 'oembed_' + key.to_s
#
#    thumbnail_key = 'thumbnail_' + key.to_s
#    oembed_options[thumbnail_key.to_sym] = 'oembed_thumbnail_' + key.to_s
#  end
#
#  oembed_providable_as :photo, oembed_options
#
#  # largest file that fits within passed in maxheight/maxwidth
#  # a nil file means nothing matches
#  def oembed_file
#    @oembed_file ||= oembed_file_for(oembed_max_dimensions)
#  end
#
#  def oembed_thumbnail_file
#    @oembed_thumbnail_file ||= oembed_file_for(oembed_max_dimensions, true)
#  end
#
#  def oembed_file_for(max_dimensions, is_thumbnail = false)
#    the_file = nil
#    if is_thumbnail
#      if !thumbnail_file.bigger_than?(max_dimensions)
#        the_file = thumbnail_file
#      else
#        # no match
#        raise ActiveRecord::RecordNotFound if the_file.nil?
#      end
#    elsif max_dimensions.values.compact.present?
#      image_files.find(:all, :order => 'size DESC').each do |image_file|
#        unless image_file.bigger_than?(max_dimensions)
#          the_file = image_file
#          break
#        end
#      end
#        # no match
#      raise ActiveRecord::RecordNotFound if the_file.nil?
#    else
#      the_file = original_file
#    end
#    the_file
#  end
#
#  def self.define_oembed_method_for(required_attribute)
#    name_adjustments = [nil, 'thumbnail']
#
#    code = nil
#    name_adjustments.each do |adjustment|
#      method_name_stub = 'oembed_'
#      method_name_stub += adjustment + '_' if adjustment
#      method_name = method_name_stub + required_attribute.to_s
#
#      file_method_name = method_name_stub + 'file'
#
#      if required_attribute == :url
#        code = Proc.new {
#          return nil unless send(file_method_name)
#
#          site_url = SystemSetting.site_url
#          site_url = site_url.chomp('/') if site_url.last == '/'
#          site_url + send(file_method_name).public_filename
#        }
#      else
#        code = Proc.new {
#          return nil unless send(file_method_name)
#          send(file_method_name).send(required_attribute)
#        }
#      end
#      define_method(method_name, &code)
#    end
#  end
#
#  OembedProvider.required_attributes[:photo].each { |attr| define_oembed_method_for(attr) }
#
#  include KeteCommonOembedSupport

  private

  def update_image_file_locations
    unless original_file.nil?
      original_file.update_attributes({ file_private: file_private })
      image_files.reject { |i| i.id == original_file.id }.each do |thumb|
        thumb.update_attributes({ file_private: private? })
      end
    end
  end
end
