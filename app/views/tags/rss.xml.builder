@title = SITE_NAME + ' - ' + @current_basket.name + ' - Latest ' + @number_per_page.to_s + ' Tags'
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(@title)
    xml.link(request.protocol + request.host + request.request_uri)
    xml.description("Tags in #{@current_basket.name}")
    xml.language('en-nz')
    for tag in @tags
      xml.item do
        xml.title(tag[:name])
        if tag[:public_taggings_count] < 1 && tag[:private_taggings_count] > 0
          @tag_search = basket_all_private_tagged_url( :urlified_name => 'site',
                                                       :privacy_type => 'private',
                                                       :controller_name_for_zoom_class => zoom_class_controller('Topic'),
                                                       :tag => tag[:id] )
        else
          @tag_search = basket_all_tagged_url( :urlified_name => 'site',
                                               :controller_name_for_zoom_class => zoom_class_controller('Topic'),
                                               :tag => tag[:id] )
        end
        xml.link(@tag_search)
        xml.guid(@tag_search)
      end
    end
  }
}
