# include ActionController::UrlWriter is already included in flagging
# methods that are needed for oembed_provider in providable models
module KeteCommonOembedSupport
  unless included_modules.include? KeteCommonOembedSupport
    def author_name
      creator.resolved_name
    end

    def author_url
      url_for(host: SystemSetting.site_name,
              controller: 'account',
              urlified_name: Basket.site_basket.urlified_name,
              action: :show, id: creator, only_path: false)
    end
  end
end
