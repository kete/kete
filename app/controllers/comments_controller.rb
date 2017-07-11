# frozen_string_literal: true

class CommentsController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('Comment')
  end

  def list
    index
  end

  def show
    @comment = Comment.find(params[:id])

    if params[:format] == 'xml'
      @comment = @current_basket.comments.find(params[:id])
      @title = @comment.title
      @creator = @comment.creator
      @last_contributor = @comment.contributors.last || @creator
    end

    respond_to do |format|
      format.html { redirect_to(comment_inplace_url(@comment)) }
      format.xml { render_oai_record_xml(item: @comment) }
    end
  end

  def new
    @comment = Comment.new

    # If we are replying to a comment, we get passed a parent_id which we need to
    # extract commentable_id, commentable_type, and commentable_private from
    unless params[:parent_id].blank?
      @parent_comment = Comment.find(params[:parent_id])
      %w(commentable_id commentable_type commentable_private).each do |attr|
        params[attr.to_sym] = @parent_comment.send(attr.to_sym).to_s
      end
      @comment.title ||= "Re: #{@parent_comment.title.gsub(/^Re:\s?/i, '')}"
      @comment.tag_list = @parent_comment.raw_tag_list
    end
  end

  def create
    @comment = Comment.new(params[:comment])

    # Reset the tag lists again to ensure they are saved to the correct privacies
    # This is required because tag_list= sets the contexted of the tags based on the private?
    # value of the @comment object.
    @comment.public_tag_list = nil
    @comment.private_tag_list = nil
    @comment.tag_list = params[:comment][:tag_list]

    @successful = @comment.save

    if @successful
      # If the parent id is set, then assign this new comment to it
      @comment.move_to_child_of Comment.find(params[:parent_id]) unless params[:parent_id].blank?

      # add this to the user's empire of creations
      # TODO: allow current_user whom is at least moderator to pick another user
      # as creator
      @comment.creator = current_user

      @comment.do_notifications_if_pending(1, current_user)

      # send notifications of private item create
      private_item_notification_for(@comment, :created) if params[:comment][:commentable_private] == '1'

      # Ensure we only use valid ZOOM CLASSes
      zoom_class = only_valid_zoom_class(params[:comment][:commentable_type])

      # make sure that we wipe comments cache for thing we are commenting on
      commented_item = zoom_class.find(params[:comment][:commentable_id])

      # although we shouldn't be using the related_topic aspect here
      # i.e. there is never going to be params[:related_topic_id]
      # this method is smart enough to do the right thing when that is the case
      setup_related_topic_and_zoom_and_redirect(@comment, commented_item,
                                                private: @comment.commentable_private,
                                                anchor: @comment.to_anchor)
    else
      render action: 'new'
    end
  end

  def edit
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    version_after_update = @comment.max_version + 1
    @comment.update_attributes(comment_params)

    if @comment.save
      @comment.add_as_contributor(current_user)
      @comment.do_notifications_if_pending(version_after_update, current_user)

      # send notifications of private comment edit
      private_item_notification_for(@comment, :edited) if params[:comment][:commentable_private] == '1'

      # make sure that we wipe comments cache for thing we are commenting on
      commented_item = @comment.commentable

      flash[:notice] = t('comments_controller.update.updated')
      redirect_to url_for(controller: zoom_class_controller(commented_item.class.name),
                          action: 'show',
                          id: commented_item,
                          anchor: @comment.to_anchor,
                          urlified_name: commented_item.basket.urlified_name,
                          private: @comment.commentable_private.to_s)
    else
      render action: 'edit'
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    commented_item = @comment.commentable
    @comment.destroy

    flash[:notice] = t('comments_controller.destroy.destroyed')

    redirect_to url_for(controller: zoom_class_controller(commented_item.class.name),
                        action: 'show',
                        id: commented_item,
                        urlified_name: commented_item.basket.urlified_name,
                        private: @comment.commentable_private.to_s)
  end

  private

  def is_authorized?
    if @current_basket.allow_non_member_comments_with_inheritance?
      return true if logged_in?
    elsif permit? comment_permit_rules
      return true
    end

    flash[:notice] = t('comments_controller.is_authorized.not_a_member')
    redirect_to DEFAULT_REDIRECTION_HASH
    false
  end

  def comment_permit_rules
    'site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket'
  end

  def comment_inplace_url(comment)
    # Link to the comment on the page it's displayed on.
    commented_item = comment.commentable
    inplace_comment_url = url_for([commented_item.basket, commented_item])
    "#{inplace_comment_url}##{comment.to_anchor}"
  end

  def comment_params
    params.require(:comment)
          .permit(:title, :description, :commentable_id, :basket_id, :raw_tag_list, :version_comment,
                  :commentable_private, :parent_id)
  end
end
