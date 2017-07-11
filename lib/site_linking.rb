module SiteLinking
  unless included_modules.include? SiteLinking
    def set_kete_net_urls
      @kete_net = 'http://kete.net.nz/site'
      @kete_sites = "#{@kete_net}/kete_sites"
      @new_kete_site = "#{@kete_sites}/new"
    end

    def check_nessesary_constants_set
      raise 'Pretty Site Name and Site URL constants are not set, are you sure you restarted your server after you configured your Kete site?' if SystemSetting.full_site_url.blank? || SystemSetting.pretty_site_name.blank?
    end

    def site_listing
      check_nessesary_constants_set
      set_kete_net_urls
      @site_listing = nil
      SiteLinkingResource.find(:all, params: { url: SystemSetting.full_site_url }).each do |link|
        link = link.attributes
        if link['url'].chomp('/') == SystemSetting.full_site_url.chomp('/') # take off the / on the end so it won't fail in some cases
          @site_listing = link
          break
        end
      end
      if @site_listing.nil?
        @site_listing = ''
      else
        @site_listing = "#{@kete_sites}/#{@site_listing['id']}"
      end
    end

    def error_linking_site
      set_kete_net_urls
      top_message = I18n.t('site_linking_lib.error_linking_site.error_occured')
      site_listing
      if @site_listing.blank?
        top_message += I18n.t('site_linking_lib.error_linking_site.manual_linking',
                              new_kete_site: @new_kete_site)
      else
        top_message += I18n.t('site_linking_lib.error_linking_site.appears_listed',
                              new_kete_site: @new_kete_site)
      end
      render :update do |page|
        page.hide('spinner')
        page.replace_html('top_message', top_message)
      end
    end
  end
end

class SiteLinkingResource < ActiveResource::Base
  self.site = 'http://kete.net.nz/site/'
  self.element_name = 'kete_site'
  self.timeout = 60
end
