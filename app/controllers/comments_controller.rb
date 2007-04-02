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
      @creator = @comment.creators.first
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

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    @comment.creators << current_user

    # make sure that we wipe comments cache for thing we are commenting on
    commented_item = Module.class_eval(params[:comment][:commentable_type]).find(params[:comment][:commentable_id])
    expire_comments_caches_for(commented_item)

    # although we shouldn't be using the related_topic aspect here
    # i.e. there is never going to be params[:related_topic_id]
    # this method is smart enough to do the right thing when that is the case
    setup_related_topic_and_zoom_and_redirect(@comment, commented_item)
  end

  def edit
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])

    if @comment.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'comment', :item_class => 'Comment'))
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @comment.version
      @comment.contributors << @current_user

      prepare_and_save_to_zoom(@comment)

      flash[:notice] = 'Comment was successfully updated.'
      redirect_to :action => 'show', :id => @comment
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('Comment')
  end
end
