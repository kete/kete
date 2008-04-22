require 'net/http'
require 'uri'

class WebLinksController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('WebLink')
  end

  def list
    index
  end

  def show
    if !has_all_fragments? or params[:format] == 'xml'
      @web_link = @current_basket.web_links.find(params[:id])
      @title = @web_link.title
    end

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @web_link.creator
      @last_contributor = @web_link.contributors.last || @creator
    end

    if !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
      @comments = @web_link.comments.find_all_non_pending
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @web_link) }
    end
  end

  def new
    @web_link = WebLink.new
  end

  def create
    @web_link = WebLink.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'web_link', :item_class => 'WebLink'))
    @successful = @web_link.save

    if @successful
      @web_link.creator = current_user
      @web_link.do_notifications_if_pending(1, current_user)
    end

    setup_related_topic_and_zoom_and_redirect(@web_link)
  end

  def edit
    @web_link = WebLink.find(params[:id])
  end

  def update
    @web_link = WebLink.find(params[:id])

    version_after_update = @web_link.max_version + 1

    if @web_link.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'web_link', :item_class => 'WebLink'))

      after_successful_zoom_item_update(@web_link)

      @web_link.do_notifications_if_pending(version_after_update, current_user)

      flash[:notice] = 'WebLink was successfully updated.'

      redirect_to_show_for(@web_link)
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('WebLink','Web link')
  end
end
