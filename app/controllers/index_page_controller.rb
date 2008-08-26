class IndexPageController < ApplicationController
  def index
    if !@current_basket.index_page_redirect_to_all.blank?
      redirect_to_all_for(@current_basket.index_page_redirect_to_all)
    else
      # Kieran Pilkington, 2008/08/06
      # Load the index page everytime (for now atleast, until a better title caching system is in place)
      @is_fully_cached = has_all_fragments?
      #if !@is_fully_cached or params[:format] == 'xml'
        @topic = @current_basket.index_topic
      #end

      if !@topic.nil?
        @title = @topic.title
      end

      if @current_basket != @site_basket or ( @topic.nil? and !@is_fully_cached )
        @title = @current_basket.name
      end

      if !@current_basket.index_topic.nil? && @current_basket.index_page_topic_is_entire_page
        render :action => :topic_as_full_page
      else
        if !@is_fully_cached

          if !has_fragment?({:part => 'details'}) and !@topic.nil?
            @comments = @topic.non_pending_comments
          end

          # TODO: DRY up
          @url_to_full_topic = nil
          @url_to_comments = nil
          if !@topic.nil?
            case @current_basket.index_page_link_to_index_topic_as
            when 'full topic and comments'
              @url_to_full_topic = url_for( :urlified_name => @topic.basket.urlified_name,
                                            :action => :show,
                                            :controller => 'topics',
                                            :id => @topic )
              @url_to_comments = url_for(:action => 'show',
                                         :urlified_name => @topic.basket.urlified_name,
                                         :controller => 'topics',
                                         :id => @topic,
                                         :anchor => 'comments')
            when 'full topic'
              @url_to_full_topic = url_for( :urlified_name => @topic.basket.urlified_name,
                                            :action => :show,
                                            :controller => 'topics',
                                            :id => @topic )
            when 'comments'
              @url_to_comments = url_for(:action => 'show',
                                         :urlified_name => @topic.basket.urlified_name,
                                         :controller => 'topics',
                                         :id => @topic,
                                         :anchor => 'comments')
            end
          end

          if !@current_basket.index_page_archives_as.blank? and @current_basket.index_page_archives_as == 'by type'
            # what are the stats on what's in the basket?
            stats_by_type_for(@current_basket)
          end


          # prepare blog list of most recent topics
          # replace limit with param from basket
          @recent_topics_limit = @current_basket.index_page_number_of_recent_topics
          if @recent_topics_limit.blank?
            @recent_topics_limit = 0
          end
          # exclude index_topic
          if @recent_topics_limit > 0
            recent_query_hash = { :limit => @recent_topics_limit, :order => 'created_at desc'}
            recent_query_hash[:conditions] = ['id != ?', @topic] unless @topic.nil?

            if @current_basket == @site_basket
              @recent_topics_items = Topic.find(:all, recent_query_hash).reject { |t| t.disputed_or_not_available? }
            else
              @recent_topics_items = @current_basket.topics.find(:all, recent_query_hash).reject { |t| t.disputed_or_not_available? }
            end
          end

          @tag_counts_array = @current_basket.tag_counts_array
        end

        # don't bother caching, because this is likely a random image
        selected_image
      end
    end
  end

  def selected_image
    # get next url from slideshow, if slideshow exists,
    # or this url is the last url in results
    # otherwise, create a new slide show based on basket settings

    # reformat into a standard_url, for results comparison in slideshow
    url_hash = { :controller => 'index_page', :action => 'selected_image' }
    @current_url = url_for(url_hash.merge(:id => params[:id]))

    # hash keys have to be strings
    # so as not to trip up later comparisons
    slideshow_key = { "basket" => @current_basket.id,
      "order" => @current_basket.index_page_image_as,
      "zoom_class" => 'StillImage' }

    if !session[:slideshow].blank? && slideshow.key == slideshow_key && !slideshow.in_set?(@current_url) && !slideshow.last_requested.blank?
      @current_url = slideshow.after(slideshow.last_requested)
    end

    id_string = @current_url.split("/").last
    if id_string =~ /([0-9]+)/
      @current_id = $1
    else
      @current_id = nil
    end

    @selected_still_image = nil

    if !session[:slideshow].blank? && slideshow.in_set?(@current_url) && slideshow.key == slideshow_key
      @selected_still_image = still_image_from_slideshow
    else
      # put together results
      # normally results are paged
      # and when you hit the last result in a page
      # the next page of results is built or something like that
      # and they are derived by hitting search controller

      limit = 20
      find_args_hash = { :select => 'id, title, created_at',
        :conditions => ['(private = :private OR private is null) AND (file_private = :file_private OR file_private is null)', {:private => false, :file_private => false}],
        :limit => limit }

      # we need public still images
      case @current_basket.index_page_image_as
      when 'random'
        find_args_hash[:order] = :random
      when 'latest'
        find_args_hash[:order] = 'created_at desc'
      end

      if @current_basket != @site_basket
        @still_image_ids = @current_basket.still_images.find(:all, find_args_hash)
      else
        @still_image_ids = StillImage.find(:all, find_args_hash)
      end

      session[:slideshow] = nil
      if !@still_image_ids.blank?
        total_images = @still_image_ids.size
        slideshow.key = slideshow_key
        slideshow.results = @still_image_ids.collect { |id| url_for(url_hash.merge(:id => id)) }
        slideshow.total = total_images
        slideshow.total_pages = 1
        slideshow.current_page = 1
        slideshow.number_per_page = total_images
        @current_id = @still_image_ids.first
        @selected_still_image = StillImage.find(@current_id)
        @current_url = url_for(url_hash.merge(:id => @current_id))
      end
    end

    @selected_image_file = ImageFile.find_by_thumbnail_and_still_image_id('medium', @selected_still_image ) if !@selected_still_image.nil?

    if !session[:slideshow].blank? && !slideshow.results.nil?
      @previous_url = slideshow.in_set?(@current_url) ? slideshow.before(@current_url) : nil
      @next_url = slideshow.in_set?(@current_url) ? slideshow.after(@current_url) : nil

      # keep track of where we are in the results
      slideshow.last_requested = !slideshow.last?(@current_url) ? @current_url : nil
    else
      @previous_url = nil
      @next_url = nil
    end

    # get still image and image_file
    if request.xhr?
      render :partial =>'selected_image',
      :locals => { :selected_image_file => @selected_image_file,
        :previous_url => @previous_url,
        :next_url => @next_url,
        :selected_still_image => @selected_still_image }
    else
      if params[:action] == 'selected_image'
        redirect_to params.merge(:action => 'index')
      end
    end
  end

  def still_image_from_slideshow
    still_image = nil
    id = @current_id || params[:id]
    if @current_basket != @site_basket
      still_image = @current_basket.still_images.find(id)
    else
      still_image = StillImage.find(id)
    end
    still_image
  end

  def topic_as_full_page
  end

  def help_file
    # Walter McGinnis, 2008-02-18
    # bug fix only
    # this needs to take a parameter for which help page
    # in the future
    # fairly brittle now
    @topic = @help_basket.topics.find_by_title("Adding things")
    @title = @topic.title
    @creator = @topic.creator
    @last_contributor = @topic.contributors.last || @creator
    @comments = @topic.comments

    render :action => :topic_as_full_page, :layout => "simple"
  end

  def uptime
    render(:text => "success")
  end

  # run a query to make sure the db is available
  # comments are usually the smallest set of items
  def db_uptime
    comment_count = Comment.count
    render(:text => "success")
  end

  # let's check to make sure zebra is responding
  # this will only return success if you can connect
  # to both the public and private databases
  # private commented out until privacy control functionality is merged in
  def zebra_uptime
    zoom_dbs = [ZoomDb.find_by_database_name('public')]
    # zoom_dbs <<  ZoomDb.find_by_database_name('private')
    zoom_dbs.each { |db| Module.class_eval('Topic').process_query(:zoom_db => db, :query => "@attr 1=_ALLRECORDS @attr 2=103 ''")}
    render(:text => "success")
  end

  def validate_kete_net_link
    render(:xml => { :url => SITE_URL, :datetime => "#{Time.new.utc.xmlschema}" })
  end

end
