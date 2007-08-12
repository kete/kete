module KeteAuthorization
  unless included_modules.include? KeteAuthorization
    def self.included(klass)
      klass.send :before_filter, :load_site_admin
      klass.send :before_filter, :load_at_least_a_moderator
      klass.send :before_filter, :load_basket_admin
      klass.send :before_filter, :load_tech_admin
    end

    # does the current user have the admin role
    # on the site basket?
    def site_admin?
      @site = @site_basket
      if logged_in?
        permit? "site_admin or admin on :site" do
          return true
        end
      end
    end

    # does the current user have the tech_admin role
    # on the site basket?
    def tech_admin?
      @site = @site_basket
      if logged_in?
        permit? "tech_admin on :site" do
          return true
        end
      end
    end

    def basket_admin?
      if @site_admin == false
        if logged_in?
          permit? "admin on :current_basket" do
            return true
          end
        end
      else
        return true
      end
    end

    def at_least_a_moderator?
      if @site_admin == false
        if logged_in?
          permit? "admin on :current_basket or moderator on :current_basket" do
            return true
          end
        end
      else
        return true
      end
    end

    def load_site_admin
      session[:site_admin] = site_admin? if session[:site_admin].nil?
      @site_admin ||= session[:site_admin]
      return true
    end

    def load_at_least_a_moderator
      @at_least_a_moderator ||= at_least_a_moderator?
      return true
    end

    def load_basket_admin
      @basket_admin ||= basket_admin?
      return true
    end

    def load_tech_admin
      @tech_admin ||= tech_admin?
      return true
    end
  end
end
