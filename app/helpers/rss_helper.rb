# ROB: This is a possible candidate for converting to a presenter.

module RssHelper
  # ROB: Methods pulled from oai_dc_helpers.rb and simplified to return strings/nil
  # So far only used for StillImages. May need some more tweaking for other content-types.

  def rss_dc_identifier(item)
    # ROB: this seemed to adjust the url if the was latest item was private. We're just ignoring this.
    rss_link_for(item)
  end

  def rss_dc_title(item)
    item.title
  end

  def rss_dc_publisher(item)
    SystemSetting.site_domain
  end

  def rss_dc_description_array(item)
    results = []

    if item.respond_to?(:short_summary)
      results << item.short_summary if item.short_summary.present?
    end

    # ROB: embedded html is stripped out because this is what old oai sources do.
    results << item.description.strip_tags if item.description.present?

    results
  end

  def rss_dc_source_for_file(item)
    if item.is_a?(StillImage) && item.original_file.nil?
      nil
    elsif ::Import::VALID_ARCHIVE_CLASSES.include?(item.class.name)
      file_url_from_bits_for(item, request[:host])
    end
  end

  def rss_dc_date(item)
    item.updated_at.utc.xmlschema
  end

  def rss_dc_creators_array(item)
    # user.login is unique per site whereas user_name is not.
    # This way we can limit exactly to one user.

    array =
      item.creators.map do |creator|
        sub_array = [creator.user_name]
        sub_array << creator.login if creator.user_name != creator.login
      end
    array.flatten
  end

  def rss_dc_contributors_array(item)
    # user.login is unique per site whereas user_name is not.
    # This way we can limit exactly to one user.

    array =
      item.contributors.select(:login).uniq.map do |contributor|
        sub_array = [contributor.user_name]
        sub_array << contributor.login if contributor.user_name != contributor.login
      end
    array.flatten
  end

  def rss_dc_relations_array(item)
    item.related_items.map do |related|
      # ROB: Previously a dc:subject tag was created using related.title. This
      #      seems unnecessary and wasn't implemented.
      rss_link_for(related)
    end
  end

  def rss_dc_type(item)
    if item.is_a? AudioRecording
      'Sound'
    elsif item.is_a? StillImage
      'StillImage'
    elsif item.is_a? Video
      'MovingImage'
    else # topic's type is the default
      'InteractiveResource'
    end
  end

  def rss_tags_to_dc_subjects_array(item)
    item.tags.map(&:name)
  end

  def rss_dc_rights(item)
    if item.respond_to?(:license) && !item.license.blank?
      item.license.url
    else
      terms_and_conditions_topic = Basket.about_basket.topics.find(:first, conditions: "UPPER(title) like '%TERMS AND CONDITIONS'")
      terms_and_conditions_topic ||= 4

      basket_topic_url(terms_and_conditions_topic.basket, terms_and_conditions_topic)
    end
  end

  def rss_dc_format(item)
    if [Topic, Comment, WebLink].include?(item.class)
      'text/html'
    elsif item.is_a?(StillImage) && item.original_file.present?
      item.original_file.content_type
    elsif item.is_a?(StillImage) && item.original_file.blank?
      nil
    else
      item.content_type
    end
  end

  # currently only relevant to topics
  def rss_dc_coverage_array(item)
    array = []

    if item.is_a?(Topic)
      item.topic_type.ancestors.each do |ancestor|
        array << ancestor.name
      end
      array << item.topic_type.name
    end

    array
  end

  def rss_dc_extended_content(item)
    ExtendedContentParser.key_value_pairs(item)
  end

  def rss_link_for(item)
    # For some reason `url_for[ item.basket, item]` gives us *_path rather than *_url strings.
    if item.is_a? AudioRecording
      basket_audio_recording_url(item.basket, item)
    elsif item.is_a? Document
      basket_document_url(item.basket, item)
    elsif item.is_a? StillImage
      basket_still_image_url(item.basket, item)
    elsif item.is_a? Topic
      basket_topic_url(item.basket, item)
    elsif item.is_a? Video
      basket_video_url(item.basket, item)
    elsif item.is_a? WebLink
      basket_web_link_url(item.basket, item)
    else
      'something has gone wrong in rss_link_for'
    end
  end
end
