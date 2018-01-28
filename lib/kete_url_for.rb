include ZoomControllerHelpers
include XmlHelpers
include Utf8UrlFor
# be able to construct a URL for a Kete item
module KeteUrlFor
  unless included_modules.include? KeteUrlFor

    # this will give us what we always use as a kete item's url
    # without privacy
    def url_for_dc_identifier(item, options = {})
      location = { controller: zoom_class_controller(item.class.name),
                   action: 'show',
                   id: item,
                   format: nil,
                   locale: false,
                   urlified_name: item.basket_or_default.urlified_name }

      location[:protocol] = 'http' if options[:force_http]

      location[:host] = options[:host] || SystemSetting.site_url

      location.merge!({ id: item.id, private: nil }) if options[:minimal]

      utf8_url_for(location)
    end

    # handles things like putting in privacy setting
    def fully_qualified_item_url(options = {}, is_relation = false)
      host = options[:host] || SystemSetting.site_url
      item = options[:item]
      controller = options[:controller]
      urlified_name = options[:urlified_name]
      protocol = options[:protocol] || appropriate_protocol_for(item)

      url = "#{protocol}://#{host}/#{urlified_name}/"
      if item.class.name == 'Comment'
        commented_on_item = item.commentable
        url += zoom_class_controller(commented_on_item.class.name) + '/show/'
        if item.should_save_to_private_zoom?
          url += "#{commented_on_item.id}?private=true"
        else
          url += (commented_on_item.to_param).to_s
        end
        url += "#comment-#{item.id}"
      elsif is_relation
        # dc:relation fields should not have titles, or ?private=true in them
        url += "#{controller}/show/#{item.id}"
      elsif options[:id]
        url += "#{controller}/show/#{options[:id]}"
      else
        if item.respond_to?(:private) && item.private?
          url += "#{controller}/show/#{item.id}?private=true"
        else
          url += "#{controller}/show/#{item.to_param}"
        end
      end
      url
    end

  end
end
