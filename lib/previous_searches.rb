# Methods for access and setting of user searches
module PreviousSearches
  unless included_modules.include? PreviousSearches

    # This gets added into application.rb so by making them helper methods here,
    # we can use them in our controllers and views throughout the site
    def self.included(klass)
      klass.helper_method :users_previous_searches
    end

    # Returns an array of hash containing the :title and :url of previous search
    # Order with the most recent search at the top
    def users_previous_searches
      if logged_in?
        @previous_searches ||= current_user.searches.collect do |s|
          { id: s.id, title: s.title, url: s.url }
        end
      else
        @previous_searches ||= session[:searches] || Array.new
      end
    end

    # Moves any searches in the session for a logged out user into the searches of whatever
    # account they just logged into. Called when logging in (AccountController#login) and
    # when signing up (AccountController#signup)
    def move_session_searches_to_current_user
      return unless logged_in? && session[:searches].is_a?(Array)
      # session[:searches] is ordered from recent -> oldest
      # reverse it so that when they are entered, their id's
      # are in the correct order
      session[:searches].reverse.each do |search|
        previous_same_search = Search.find_by_user_id_and_url(current_user.id, search[:url])
        if previous_same_search
          previous_same_search.update_attribute(:updated_at, Time.now)
        else
          current_user.searches.create(title: search[:title], url: search[:url])
        end
      end
      session[:searches] = Array.new
    end

    def save_current_search
      title, url = short_search_title_from_params, current_request_url
      return if @search.nil? || url.blank?

      if logged_in?
        previous_same_search = current_user.searches.find_by_url(url)
        if previous_same_search
          previous_same_search.update_attribute(:updated_at, Time.now)
        else
          @search.user = current_user
          @search.title = title
          @search.url = url
          @search.save
        end
      else
        session[:searches] ||= Array.new
        previous_same_search = session[:searches].find { |s| s[:url] == url }
        if previous_same_search
          index_in_searches = session[:searches].index(previous_same_search)
          previous_search = session[:searches].delete_at(index_in_searches)
          session[:searches].unshift(previous_search)
        else
          session[:searches].unshift(title: title, url: url)
        end
      end
    end

    def clear_users_previous_searches(id = nil)
      if logged_in?
        id ? current_user.searches.find(id).destroy : current_user.searches.destroy_all
      else
        id ? session[:searches].delete_at(id) : session[:searches] = Array.new
      end
    end

    private

    # libt cuts down repeated translation logic
    def libt(key, *args)
      I18n.t("previous_searches_lib.short_search_title_from_params.#{key}", *args)
    end

    # A slimmed down version of the last_part_of_title_if_refinement_of method in SearchHelper
    def short_search_title_from_params
      zoom_class = zoom_class_from_controller(params[:controller_name_for_zoom_class])
      plural_item_type = zoom_class_plural_humanize(zoom_class)
      title_parts = Array.new
      title_parts << libt(:search_terms, search_terms: params[:search_terms]) if params[:action] == 'for'
      title_parts << libt(:topic_type, topic_type_name: @topic_type.name) if @topic_type
      title_parts << libt(:tag, tag_name: @tag.name) if @tag
      title_parts << libt(:contributor, contributor_name: @contributor.user_name) if @contributor
      title_parts << libt(:extended_field, extended_field: @extended_field.label.singularize.downcase) if @extended_field
      title_parts << libt(:limit_to_choice, choice_name: @limit_to_choice.label) if @limit_to_choice
      if @source_item
        @source_item.private_version! if permitted_to_view_private_items? && @source_item.latest_version_is_private?
        title_parts << libt(:source_item, source_item_name: @source_item.title)
      end
      title_parts << libt(:date_since, since: @date_since) if @date_since
      title_parts << libt(:date_until, until: @date_until) if @date_until
      title_parts << libt(:type_and_basket, all: ('all' if params[:action] != 'for').to_s, privacy: @privacy.to_s,
                                            item_type: plural_item_type, basket_name: @current_basket.name).strip
      title_parts << libt(:sort_type, sort_type: params[:sort_type]) if params[:sort_type] && params[:sort_type] != 'none'
      title_parts << libt(:in_reverse) if params[:sort_direction] == 'reverse'
      title_parts.compact.join(', ')
    end

    # Take the request url, remove any trailing slash, split the params, remove empty ones
    # then order them and put the URL back together. This helps ensure that whatever order
    # the params come in, it'll see previous searches of the same params
    def current_request_url
      url, params = request.url.split('?')
      url = url.gsub(/\/$/, '') rescue nil
      params = params.split('&').delete_if { |param| param =~ /=$/ }.sort.join('&') rescue nil
      [url, params].compact.join('?')
    end

  end
end
