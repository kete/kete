class CommentsController < ApplicationController
  include ExtendedContentController
  
  def index
    redirect_to_search_for('Comment')
  end

  def list
    index
  end

  def show
    if !has_all_fragments? or params[:format] == 'xml'
      @comment = @current_basket.comments.find(params[:id])
      @title = @comment.title
    end

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @comment.creator
      @last_contributor = @comment.contributors.last || @creator
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @comment) }
    end
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'comment', :item_class => 'Comment'))
    @successful = @comment.save

    if @successful
      # add this to the user's empire of creations
      # TODO: allow current_user whom is at least moderator to pick another user
      # as creator
      @comment.creator = current_user

      @comment.do_notifications_if_pending(1, current_user)

      # make sure that we wipe comments cache for thing we are commenting on
      commented_item = Module.class_eval(params[:comment][:commentable_type]).find(params[:comment][:commentable_id])
      expire_comments_caches_for(commented_item)

      # although we shouldn't be using the related_topic aspect here
      # i.e. there is never going to be params[:related_topic_id]
      # this method is smart enough to do the right thing when that is the case
      setup_related_topic_and_zoom_and_redirect(@comment, commented_item, :private => @comment.commentable_private)
    else
      render :action => 'new'
    else
      render :action => 'new'
    end
  end

  def edit
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])

    version_after_update = @comment.max_version + 1

    if @comment.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'comment', :item_class => 'Comment'))

      @comment.add_as_contributor(current_user)

      @comment.do_notifications_if_pending(version_after_update, current_user)

      # make sure that we wipe comments cache for thing we are commenting on
      commented_item = @comment.commentable
      expire_comments_caches_for(commented_item)

      prepare_and_save_to_zoom(@comment)

      prepare_and_save_to_zoom(commented_item)
      
      flash[:notice] = 'Comment was successfully updated.'
      redirect_to url_for(:controller => zoom_class_controller(commented_item.class.name),
                          :action => 'show',
                          :id => commented_item,
                          :anchor => @comment.id,
                          :urlified_name => commented_item.basket.urlified_name,
                          :private => @comment.commentable_private.to_s)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @comment = Comment.find(params[:id])

    # make sure that we wipe comments cache for thing we are commenting on
    commented_item = @comment.commentable

    prepare_zoom(@comment)
    @successful = @comment.destroy

    if @successful
      expire_comments_caches_for(commented_item)
      prepare_and_save_to_zoom(commented_item)

      flash[:notice] = 'Comment was successfully deleted.'

      redirect_to url_for(:controller => zoom_class_controller(commented_item.class.name),
                          :action => 'show',
                          :id => commented_item,
                          :urlified_name => commented_item.basket.urlified_name, 
                          :private => @comment.commentable_private.to_s)
    end
  end
  
  private
  
    def is_authorized?
      if @current_basket.allow_non_member_comments?
        permitted = logged_in?
      else
        permitted = permit? "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket"
      end
      
      unless permitted
        flash[:notice] = "Sorry, you need to be a member to leave a comment in this basket."
        redirect_to DEFAULT_REDIRECTION_HASH
        false
      end
    end
     
end
