class ContentTypesController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :site"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to :action => 'list'
  end

  def list
    @content_types = ContentType.paginate(:page => params[:page], :per_page => 10, :order => 'controller')
  end

  def new
    @content_type = ContentType.new
  end

  def create
    @content_type = ContentType.new(params[:content_type])
    if @content_type.save
      # TODO: globalize translate
      flash[:notice] = 'Content type was successfully created.'
      redirect_to :action => 'edit', :id => @content_type
    else
      render :action => 'new'
    end
  end

  def edit
    @content_type = ContentType.find(params[:id])
  end

  def update
    @content_type = ContentType.find(params[:id])
    if @content_type.update_attributes(params[:content_type])
      # TODO: globalize translate
      flash[:notice] = 'Content type was successfully updated.'
      redirect_to :action => 'edit', :id => @content_type
    else
      render :action => 'edit'
    end
  end

  # TODO: possibly remove, at the least put high restrictions on
  def destroy
    ContentType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_to_content_type
    content_type = ContentType.find(params[:id])

    # this is setup for a form that has multiple fields
    # we want to separate out plain form fields from required ones

    # params has a hash of hashes for field with field_id as the key
    params[:extended_field].keys.each do |field_id|
      field = ExtendedField.find(field_id)

      # into the field's hash
      # now we can grab the field's attributes that are being updated
      params[:extended_field][field_id].keys.each do |to_add_attr|
        to_add_attr_value = params[:extended_field][field_id][to_add_attr]

        # if we are supposed to add the field
        if to_add_attr_value.to_i == 1

          # determine if it should be a required field
          # or just an optional one
          if to_add_attr =~ /required/
            content_type.required_form_fields << field
          else
            content_type.form_fields << field
          end
        end
      end
    end
    redirect_to :action => :edit, :id => content_type
  end

  def reorder_fields_for_content_type
    # update position in the content_type's form
    ContentTypeToFieldMapping.update(params[:mapping].keys, params[:mapping].values)
    redirect_to :action => :edit, :id => params[:id]
  end

end
