class TopicTypesController < ApplicationController
  include FieldMappingsController

  def list
    @topic_types = TopicType.find(1).full_set.paginate(page: params[:page], per_page: 10)
  end

  def new
    @topic_type = TopicType.new
  end

  def edit
    @topic_type = TopicType.find(params[:id])
  end

  private

  def set_ancestory(topic_type)
      # setup of ancestory
      parent_id = params[:parent_id] || topic_type.parent_id || 1
      topic_type.move_to_child_of TopicType.find(parent_id)
  end

end
