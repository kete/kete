# frozen_string_literal: true

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
      logged_in? && permit?('site_admin or admin on :site') || nil
    end

    # does the current user have the tech_admin role
    # on the site basket?
    def tech_admin?
      @site = @site_basket
      logged_in? && permit?('tech_admin on :site')
    end

    # one role up the hierarchy tests for all the roles above it
    def basket_admin?(basket = nil)
      @basket = basket || @current_basket
      @site_admin || (logged_in? && permit?('admin on :basket'))
    end

    def basket_moderator?(basket = nil)
      @basket = basket || @current_basket
      @basket_admin || (logged_in? && permit?('moderator on :basket'))
    end

    alias at_least_a_moderator? basket_moderator?

    def basket_member?(basket = nil)
      @basket = basket || @current_basket
      @basket_moderator || (logged_in? && permit?('member on :basket'))
    end

    def load_site_admin
      @site_admin = site_admin?
      true
    end

    def load_at_least(basket = nil)
      if !basket.nil?
        @at_least_site_admin_of_specified_basket ||= site_admin?
        @at_least_admin_of_specified_basket ||= basket_admin?(basket)
        @at_least_moderator_of_specified_basket ||= basket_moderator?(basket)
        @at_least_member_of_specified_basket ||= basket_member?(basket)
      else
        @at_least_site_admin ||= site_admin?
        @at_least_admin ||= basket_admin?
        @at_least_moderator ||= basket_moderator?
        # setting for legacy support
        @at_least_a_moderator ||= @at_least_moderator
        @at_least_member ||= basket_member?
      end
      true
    end

    def load_basket_admin
      @basket_admin ||= basket_admin?
      true
    end

    def load_basket_moderator
      @basket_moderator ||= basket_moderator?
      true
    end

    def load_basket_member
      @basket_member ||= basket_member?
      true
    end

    def load_tech_admin
      @tech_admin ||= tech_admin?
      true
    end
  end
end
