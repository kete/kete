module KeteAuthorization
  unless included_modules.include? KeteAuthorization
    def self.included(klass)
      klass.send :before_filter, :load_site_admin
      klass.send :before_filter, :load_tech_admin
      klass.send :before_filter, :load_basket_admin
      klass.send :before_filter, :load_basket_moderator
      klass.send :before_filter, :load_basket_member
      klass.send :before_filter, :load_at_least
    end

    # TODO: prime for DRYing up with metaprogramming

    # does the current user have the admin role
    # on the site basket?
    def site_admin?
      @site = @site_basket
      logged_in? && permit?("site_admin or admin on :site") || nil
    end

    # does the current user have the tech_admin role
    # on the site basket?
    def tech_admin?
      @site = @site_basket
      logged_in? && permit?("tech_admin on :site")
    end

    # one role up the hierarchy tests for all the roles above it
    def basket_admin?
      @site_admin || ( logged_in? && permit?("admin on :current_basket") )
    end

    def basket_moderator?
      @basket_admin || ( logged_in? && permit?("moderator on :current_basket") )
    end

    alias_method :at_least_a_moderator?, :basket_moderator?

    def basket_member?
       @basket_moderator || ( logged_in? && permit?("member on :current_basket") )
    end

    def load_site_admin
      session[:site_admin] = site_admin? if session[:site_admin].nil?
      @site_admin ||= session[:site_admin]
      return true
    end

    def load_at_least
      @at_least_site_admin ||= site_admin?
      @at_least_admin ||= basket_admin?
      @at_least_moderator ||= basket_moderator?
      # setting for legacy support
      @at_least_a_moderator ||= @at_least_moderator
      @at_least_member ||= basket_member?
      return true
    end

    def load_basket_admin
      @basket_admin ||= basket_admin?
      return true
    end

    def load_basket_moderator
      @basket_moderator ||= basket_moderator?
      return true
    end

    def load_basket_member
      @basket_member ||= basket_member?
      return true
    end

    def load_tech_admin
      @tech_admin ||= tech_admin?
      return true
    end
  end
end
