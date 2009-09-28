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
    @web_link = prepare_item_and_vars

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @web_link) }
    end
  end

  def new
    @web_link = WebLink.new
  end

  def create
    @web_link = WebLink.new(params[:web_link])
    @successful = @web_link.save

    if @successful
      @web_link.creator = current_user
      @web_link.do_notifications_if_pending(1, current_user)
    end

    setup_related_topic_and_zoom_and_redirect(@web_link, nil, :private => (params[:web_link][:private] == "true"))
  end

  def edit
    @web_link = WebLink.find(params[:id])
    public_or_private_version_of(@web_link)
  end

  def update
    @web_link = WebLink.find(params[:id])

    version_after_update = @web_link.max_version + 1

    @successful = ensure_no_new_insecure_elements_in('web_link')
    @web_link.attributes = params[:web_link]
    @successful = @web_link.save if @successful

    if @successful

      after_successful_zoom_item_update(@web_link, version_after_update)
      flash[:notice] = t('web_links_controller.update.updated')

      redirect_to_show_for(@web_link, :private => (params[:web_link][:private] == "true"))
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('WebLink','Web link')
  end
end
