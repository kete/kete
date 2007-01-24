class TopicTypesController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to :action => 'list'
  end

  def list
    @topic_type_pages = Paginator.new self, TopicType.count, 10, params[:page]
    @topic_types = TopicType.find(1).full_set
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
      redirect_to :action => 'list'
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
      set_ancestory(@topic_type)

      # TODO: globalize translate
      flash[:notice] = 'TopicType was successfully updated.'
      redirect_to :action => 'show', :id => @topic_type
    else
      render :action => 'edit'
    end
  end

  def destroy
    TopicType.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_to_topic_type
    topic_type = TopicType.find(params[:id])

    # this is setup for a form that has multiple fields
    # we want to separate out plain form fields from required ones

    # params has a hash of hashes for field with field_id as the key
    params[:topic_type_field].keys.each do |field_id|
      field = TopicTypeField.find(field_id)

      # into the field's hash
      # now we can grab the field's attributes that are being updated
      params[:topic_type_field][field_id].keys.each do |to_add_attr|
        to_add_attr_value = params[:topic_type_field][field_id][to_add_attr]

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
    redirect_to :action => :index
  end

  def reorder_fields_for_topic_type
    # update position in the topic_type's form
    TopicTypeToFieldMapping.update(params[:mapping].keys, params[:mapping].values)
    redirect_to :action => :index
  end

  private
  def set_ancestory(topic_type)
      # setup of ancestory
      parent_id = params[:parent_id] || topic_type.parent_id || 1
      topic_type.move_to_child_of TopicType.find(parent_id)
  end

end
