class ContentTypesController < ApplicationController
  include FieldMappingsController

  def list
    @content_types = ContentType.paginate(:page => params[:page], :per_page => 10, :order => 'controller')
  end

  def new
    @content_type = ContentType.new
  end

  def edit
    @content_type = ContentType.find(params[:id])
  end

end
