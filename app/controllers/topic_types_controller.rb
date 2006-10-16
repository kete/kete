class TopicTypesController < ApplicationController
  ajax_scaffold :topic_type
  def add_to_topic_type
    topic_type = TopicType.find(params[:id])

    # we want to separate out plain form fields from required ones
    params[:topic_type_field].keys.each do |field_id|
      field = TopicTypeField.find_by_id(field_id)
      params[:topic_type_field][field_id].keys.each do |to_add_attr|
        to_add_attr_value = params[:topic_type_field][field_id][to_add_attr]
        if to_add_attr_value.to_i == 1
          if to_add_attr =~ /required/
            topic_type.required_form_fields << field
          else
            topic_type.form_fields << field
          end
        end
      end
    end
    redirect_to :action => :index
    # TODO: figure out how to re-render with ajaxscaffold
    #redirect_to :action => :edit, :id => topic_type.id, :scaffold_id => :topic_type unless request.xhr?
  end
  def reorder_fields_for_topic_type
    # update position in the topic_type's form
    TopicTypeToFieldMapping.update(params[:mapping].keys, params[:mapping].values)
    # TODO: figure out how to re-render with ajaxscaffold
    # redirect_to(:action => :edit, :id => params[:id], :scaffold_id => :topic_type) unless request.xhr?
    redirect_to :action => :index
  end
end
