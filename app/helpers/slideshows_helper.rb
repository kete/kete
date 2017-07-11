module SlideshowsHelper

  # James - 2008-07-04
  # Helpers specific to slideshow/results navigation

  def link_to_next_in_slideshow(text = t('slideshows_helper.next'), current_url = request.url)
    current_url = url_without_extras(current_url)
    return nil if slideshow.last_result?(current_url)

    if next_result = slideshow.after(current_url)
      url = next_result
      url = append_options_to_url(url, "view_size=#{slideshow.image_view_size}") if slideshow.image_view_size

      link_to text, url_for(url)
    else

      # We need to load the next page of results into the session to continue
      link_to text, slideshow.search_params.merge('action' => 'slideshow_page_load', 'page' => slideshow.current_page + 1, 'direction' => 'up')
    end
  end

  def link_to_previous_in_slideshow(text = t('slideshows_helper.previous'), current_url = request.url)
    current_url = url_without_extras(current_url)
    return nil if slideshow.first_result?(current_url)

    if previous_result = slideshow.before(current_url)
      url = previous_result
      url = append_options_to_url(url, "view_size=#{slideshow.image_view_size}") if slideshow.image_view_size
      link_to text, url_for(url)
    else

      # We need to load the previous page of results into the session to continue
      link_to text, slideshow.search_params.merge('action' => 'slideshow_page_load', 'page' => slideshow.current_page - 1, 'direction' => 'down')
    end
  end

  def link_to_results(text = t('slideshows_helper.all_results'))
    link_to text, slideshow.redirect_to_results_hash
  end

  def link_to_stop_slideshow(text = t('slideshows_helper.stop'))
    link_to text, controller: 'search', action: 'clear_slideshow', return_to: request.url
  end

  def show_slideshow_controls?(current_url = request.url)
    # Walter McGinnis, 2008-08-12
    # putting in check whether there is only one result
    # navigable? checks if there is more than 0
    # i think we want more than 1
    !session[:slideshow].blank? &&
      !slideshow.results.blank? &&
      slideshow.navigable? &&
      slideshow.in_set?(url_without_extras(current_url)) &&
      !(slideshow.results.size < 2) &&
      
      # James - 2008-11-19
      # Factored out slideshow controls partial rendering statement to application.rhtml, so we need to check that the controller
      # and action are right now as the partial is no longer called from the 'show' view for each item type.
      %w(audio documents images topics video web_links).member?(params[:controller]) &&
      params[:action] == 'show'
  end

  private

    # Support for keeping view size for images
    def url_without_extras(url)

      # Store the view size and return the URL without the matching part.
      if url =~ /view_size=([a-z_]+)$/ && %w{small_sq medium small large}.member?($1)
        slideshow.image_view_size = $1
      else
        slideshow.image_view_size = nil
      end

      # Remove anything that won't match the dc:identifier for the current item
      url.gsub!(/[\?&]view_size=[a-z_]+/, '')
      url.gsub!(/[\?&]private=false/, '')

      # If private=true is tacked on to the end of a long query string, switch the
      # ampersand for a question mark like in dc:identifier so we get a match.
      url.gsub!(/&private=true/, '?private=true')

      url
    end

end
