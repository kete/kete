module FieldMappingsController
  unless included_modules.include? FieldMappingsController

    def self.included(klass)
      klass.send :before_filter, :login_required, :only => [:list, :index]
      klass.send :permit, "site_admin or admin of :site"

      # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
      klass.send :verify, :method => :post, :only => [ :destroy, :create, :update ],
                          :redirect_to => { :action => :list }
    end

    def index
      redirect_to :action => 'list'
    end

    def create
      param_name = params[:controller].singularize.to_sym
      item = item_type_class.new(params[param_name])

      if item.save
        set_ancestory(item) if item.class == TopicType
        flash[:notice] = "#{item.class.name.underscore.humanize} was successfully created."
        set_instance_var_for(item)
        redirect_to :urlified_name => @site_basket.urlified_name, :action => 'edit', :id => item
      else
        set_instance_var_for(item)
        render :action => 'new'
      end
    end

    def update
      param_name = params[:controller].singularize.to_sym
      item = item_type_class.find(params[:id])

      if item.update_attributes(params[param_name])
        if item.class == TopicType
          # expire show details for all topics of this type
          # since it displays the topic_type.name
          item.topics.each do |topic|
            expire_fragment(:controller => 'topics', :urlified_name => topic.basket.urlified_name, :action => 'show', :id => topic, :part => 'details')
          end
        end

        flash[:notice] = "#{item.class.name.underscore.humanize} was successfully updated."
        set_instance_var_for(item)
        redirect_to :urlified_name => @site_basket.urlified_name, :action => 'edit', :id => item
      else
        set_instance_var_for(item)
        render :action => 'edit'
      end
    end

    def destroy
      item = item_type_class.find(params[:id])
      successful = item.destroy

      if successful
        flash[:notice] = "#{item.class.name.underscore.humanize} was successfully deleted."
        redirect_to :urlified_name => @site_basket.urlified_name, :action => 'list'
      end
    end

    def add_to_item_type
      item = item_type_class.find(params[:id])

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
              item.required_form_fields << field
            else
              item.form_fields << field
            end
          end
        end
      end
      redirect_to :urlified_name => @site_basket.urlified_name, :action => 'edit', :id => item
    end

    def reorder_fields
      field_mapping_class.update(params[:mapping].keys, params[:mapping].values)
      redirect_to :urlified_name => @site_basket.urlified_name, :action => 'edit', :id => params[:id]
    end

    def remove_mapping
      mapping = field_mapping_class.find(params[:mapping_id])

      if mapping.used_by_items?
        flash[:error] = "The #{mapping.extended_field.label} mapping is in use by this #{item_type_class.name.underscore.humanize} or its descendants and cannot be deleted."
      else
        mapping.destroy
        flash[:notice] = "The #{mapping.extended_field.label} mapping has been deleted."
      end

      redirect_to :urlified_name => @site_basket.urlified_name, :action => 'edit', :id => params[:id]
    end

    private

    def item_type_class
      params[:controller] == 'topic_types' ? TopicType : ContentType
    end

    def field_mapping_class
      params[:controller] == 'topic_types' ? TopicTypeToFieldMapping : ContentTypeToFieldMapping
    end

    def set_instance_var_for(item)
      if item.class == TopicType
        @topic_type = item
      else
        @content_type = item
      end
    end

  end
end