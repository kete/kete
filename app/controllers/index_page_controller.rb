class IndexPageController < ApplicationController
  def index
    if !@current_basket.index_page_redirect_to_all.blank?
      redirect_to_all_for(@current_basket.index_page_redirect_to_all)
    else
      @is_fully_cached = has_all_fragments?
      prepare_topic_for_show

      if @current_basket != @site_basket or ( @topic.nil? and @is_fully_cached == false )
        @title = @current_basket.name
      else
        if @is_fully_cached == false
            @title = @topic.title
        end
      end

      if @current_basket.index_page_topic_is_entire_page
        render :action => :topic_as_full_page
      else
        if @is_fully_cached == false
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
          # exclude index_topic
          if @recent_topics_limit > 0
            if @current_basket == @site_basket
              @recent_topics_items = Topic.find(:all,
                                                :limit => @recent_topics_limit,
                                                :conditions => ['id != ?', @topic],
                                                :order => 'created_at desc')
            else
              @recent_topics_items = @current_basket.topics.find(:all,
                                                                 :limit => @recent_topics_limit,
                                                                 :conditions => ['id != ?', @topic],
                                                                 :order => 'created_at desc')
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
    @selected_still_image = nil
    case @current_basket.index_page_image_as
    when 'random'
      if @current_basket != @site_basket
        @selected_still_image = @current_basket.still_images.find(:first, :order => 'Rand()')
      else
        @selected_still_image = StillImage.find(:first, :order => 'Rand()')
      end
    when 'latest'
      if @current_basket != @site_basket
        @selected_still_image = @current_basket.still_images.find(:first, :order => 'created_at desc')
      else
        @selected_still_image = StillImage.find(:first, :order => 'created_at desc')
      end
    end

    if !@selected_still_image.nil?
      @selected_image_file = ImageFile.find_by_thumbnail_and_still_image_id('medium', @selected_still_image )
    end

    if request.xhr?
      render :partial =>'selected_image',
      :locals => { :selected_image_file => @selected_image_file,
        :selected_still_image => @selected_still_image }
    else
      if params[:action] == 'selected_image'
        redirect_to params.merge(:action => 'index')
      end
    end
  end

  def topic_as_full_page
  end

  def help_file
    @is_fully_cached = has_all_fragments?
    prepare_topic_for_show

    if @topic.nil? and @is_fully_cached == false
      @title = @current_basket.name
    else
      if @is_fully_cached == false
        @title = @topic.title
      end
    end
    render :action => :topic_as_full_page, :layout => "layouts/simple"
  end

  def uptime
    render(:text => "success")
  end

end
