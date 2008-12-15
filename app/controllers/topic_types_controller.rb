class TopicTypesController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :site"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    list
    render :action => 'list'
  end

  def list
    @topic_types = TopicType.find(1).full_set.paginate(:page => params[:page], :per_page => 10)
  end

  def show
    @topic_type = TopicType.find(params[:id])
  end

  def new
    @topic_type = TopicType.new
  end

  def create
    @topic_type = TopicType.new(params[:topic_type])
    if @topic_type.save
      set_ancestory(@topic_type)

      # TODO: globalize translate
      flash[:notice] = 'TopicType was successfully created.'
      redirect_to :urlified_name => 'site', :action => 'edit', :id => @topic_type
    else
      render :action => 'new'
    end
  end

  def edit
    @topic_type = TopicType.find(params[:id])
  end

  def update
    @topic_type = TopicType.find(params[:id])
    if @topic_type.update_attributes(params[:topic_type])
      # this isn't a move, so resetting ancestory isn't necessary
      # set_ancestory(@topic_type)

      # expire show details for all topics of this type
      # since it displays the topic_type.name
      @topic_type.topics.each do |topic|
        expire_fragment(:controller => 'topics', :urlified_name => topic.basket.urlified_name, :action => 'show', :id => topic, :part => 'details')
      end

      # TODO: globalize translate
      flash[:notice] = 'TopicType was successfully updated.'
      redirect_to :urlified_name => 'site', :action => 'edit', :id => @topic_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    @topic_type = TopicType.find(params[:id])
    @successful = @topic_type.destroy
    if @successful
      flash[:notice] = 'TopicType was successfully deleted.'
      redirect_to :urlified_name => 'site', :action => 'list'
    end
  end

  def add_to_topic_type
    topic_type = TopicType.find(params[:id])

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
            topic_type.required_form_fields << field
          else
            topic_type.form_fields << field
          end
        end
      end
    end
    redirect_to :urlified_name => 'site', :action => 'edit', :id => topic_type
  end

  def reorder_fields_for_topic_type
    # update position in the topic_type's form
    TopicTypeToFieldMapping.update(params[:mapping].keys, params[:mapping].values)
    redirect_to :urlified_name => 'site', :action => 'edit', :id => params[:id]
  end

  private
  def set_ancestory(topic_type)
      # setup of ancestory
      parent_id = params[:parent_id] || topic_type.parent_id || 1
      topic_type.move_to_child_of TopicType.find(parent_id)
  end

end
