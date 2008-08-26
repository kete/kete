require 'net/http'
require 'uri'

class WebLinksController < ApplicationController
  include ExtendedContentController
  
  helper :privacy_controls

  def index
    redirect_to_search_for('WebLink')
  end

  def list
    index
  end

  def show
    prepare_item_variables_for("WebLink")
    @web_link = @item

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @web_link) }
    end
  end

  def new
    @web_link = WebLink.new({ :private => @current_basket.private_default || false, 
                              :file_private =>  @current_basket.file_private_default || false })
  end

  def create
    @web_link = WebLink.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'web_link', :item_class => 'WebLink'))
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

    if @web_link.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'web_link', :item_class => 'WebLink'))

      after_successful_zoom_item_update(@web_link)

      @web_link.do_notifications_if_pending(version_after_update, current_user) if 
        @web_link.versions.exists?(:version => version_after_update)

      flash[:notice] = 'WebLink was successfully updated.'

      redirect_to_show_for(@web_link, :private => (params[:web_link][:private] == "true"))
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('WebLink','Web link')
  end
end
