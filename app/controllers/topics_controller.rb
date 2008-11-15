class TopicsController < ApplicationController
  permit "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket", :only => [ :new, :create, :edit, :update]

  # moderators only
  permit "site_admin or moderator of :current_basket or admin of :current_basket", :only =>  [ :destroy, :restore, :reject ]

  # override the site wide protect_from_forgery to exclude
  # things that you must be logged in to do anyway or at least a moderator
  protect_from_forgery :secret => KETE_SECRET, :except => ['new', 'destroy']

  # since we use dynamic forms based on topic_types and extended_fields
  # and topics have their main attributes stored in an xml doc
  # within their content field
  # in fact none of the topics table fields are edited directly
  # we don't do CRUD for topics directly
  # instead we override CRUD here, as well as show
  # and use app/views/topics/_form.rhtml to customize
  # we'll start with using the override syntax for ajaxscaffold
  # the code should easily transferred to something else if we decide to drop it

  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce :options => DEFAULT_TINYMCE_SETTINGS,
                :only => VALID_TINYMCE_ACTIONS
  ### end TinyMCE WYSIWYG editor stuff

  # stuff related to flagging and moderation
  include FlaggingController

  # Get the Privacy Controls helper
  helper :privacy_controls

  def index
    redirect_to_search_for('Topic')
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    index
  end

  def show
    prepare_item_variables_for('Topic')
    @topic = @item

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @topic) }
    end
  end

  def new
    @topic = Topic.new
    respond_to do |format|
      format.html
      format.js { render :file => File.join(RAILS_ROOT, 'app/views/topics/pick_form.js.rjs') }
    end
  end

  def edit
    @topic = Topic.find(params[:id])
    public_or_private_version_of(@topic)

    # logic to prevent plain old members from editing
    # site basket homepage
    if @topic != @site_basket.index_topic or permit? "site_admin of :site_basket or admin of :site_basket"
      @topic_types = @topic.topic_type.full_set
    else
      # this is the site's index page, but they don't have permission to edit
      flash[:notice] = 'You don\'t have permission to edit this topic.'
      redirect_to :action => 'show', :id => params[:id]
    end
  end

  def create
    begin
      # since this is creation, grab the topic_type fields
      topic_type = TopicType.find(params[:topic][:topic_type_id])

      @fields = topic_type.topic_type_to_field_mappings

      # work through inherited fields as well as current topic_type
      @ancestors = TopicType.find(topic_type).ancestors
      # everything descends from topic topic_type,
      # so there is always at least one ancestor
      if @ancestors.size > 1
        @ancestors.each do |ancestor|
          @fields = @fields + ancestor.topic_type_to_field_mappings
        end
      end

      # ultimately I would like url's for peole to do look like the following:
      # topics/people/mcginnis/john
      # topics/people/mcginnis/john_marshall
      # topics/people/mcginnis/john_robert
      # for places:
      # topics/places/nz/wellington/island_bay/the_parade/206
      # events:
      # topics/events/2006/10/31
      # in the meantime we'll just use :name or :first_names and :last_names

      # here's where we populate the extended_content with our xml
      if @fields.size > 0
        extended_fields_update_param_for_item(:fields => @fields, :item_key => 'topic')
      end

      # in order to get the ajax to work, we put form values in the topic hash
      # in parameters, this will break new and update, because they aren't apart of the model
      # directly, so strip them out of parameters

      replacement_topic_hash = extended_fields_replacement_params_hash(:item_key => 'topic', :item_class => 'Topic')
      @topic = Topic.new(replacement_topic_hash)
      @successful = @topic.save


      # add this to the user's empire of creations
      # TODO: allow current_user whom is at least moderator to pick another user
      # as creator
      @topic.creator = current_user if @successful
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    where_to_redirect = 'show_self'
    if params[:relate_to_topic] and @successful
      @new_related_topic = Topic.find(params[:relate_to_topic])
      ContentItemRelation.new_relation_to_topic(@new_related_topic, @topic)

      # update the related topic
      # so this new relationship is reflected in search
      prepare_and_save_to_zoom(@new_related_topic)

      # make sure the related topics cache is cleared for related topic
      expire_related_caches_for(@new_related_topic, 'topics')

      where_to_redirect = 'show_related'
    end

    if params[:index_for_basket] and @successful
      where_to_redirect = 'basket'
    end

    if @successful
      prepare_and_save_to_zoom(@topic)

      @topic.do_notifications_if_pending(1, current_user)

      case where_to_redirect
      when 'show_related'
        flash[:notice] = 'Related topic was successfully created.'
        redirect_to_related_topic(@new_related_topic.id)
      when 'basket'
        redirect_to :action => 'add_index_topic',
        :controller => 'baskets',
        :index_for_basket => params[:index_for_basket],
        :topic => @topic
      else
        flash[:notice] = 'Topic was successfully created.'
        params[:topic] = replacement_topic_hash
        redirect_to :action => 'show', :id => @topic, :private => (params[:topic][:private] == "true")
      end
    else
        render :action => 'new'
    end
  end

  def update
    begin
      @topic = Topic.find(params[:id])

      # logic to prevent plain old members from editing
      # site basket homepage
      if @topic != @site_basket.index_topic or permit? "site_admin of :site_basket or admin of :site_basket"
        # using the new topic type value, just in case we add ajax update
        # of form in the future
        topic_type = TopicType.find(params[:topic][:topic_type_id])

        @fields = topic_type.topic_type_to_field_mappings

        # work through inherited fields as well as current topic_type
        @ancestors = TopicType.find(topic_type).ancestors
        # everything descends from topic topic_type,
        # so there is always at least one ancestor
        if @ancestors.size > 1
          @ancestors.each do |ancestor|
            @fields = @fields + ancestor.topic_type_to_field_mappings
          end
        end

        if @fields.size > 0
          extended_fields_update_param_for_item(:fields => @fields, :item_key => 'topic')
        end

        # in order to get the ajax to work, we put form values in the topic hash
        # in parameters, this will break new and update, because they aren't apart of the model
        # directly, so strip them out of parameters

        replacement_topic_hash = extended_fields_replacement_params_hash(:item_key => 'topic', :item_class => 'Topic')

        version_after_update = @topic.max_version + 1

        @successful = @topic.update_attributes(replacement_topic_hash)
      else
        # they don't have permission
        # this will redirect them to edit
        # which will bump them back to show for the topic
        # with flash message
        @successful = false
      end
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    params[:topic] = replacement_topic_hash

    if @successful
      after_successful_zoom_item_update(@topic)

      @topic.do_notifications_if_pending(version_after_update, current_user) if
        @topic.versions.exists?(:version => version_after_update)

      # TODO: replace with translation stuff when we get globalize going
      flash[:notice] = 'Topic was successfully edited.'

      redirect_to_show_for @topic, :private => (params[:topic][:private] == "true")
    else
      if @topic != @site_basket.index_topic or permit? "site_admin of :site_basket or admin of :site_basket"
        @topic_types = @topic.topic_type.full_set
      end
      render :action => 'edit'
    end
  end

  def destroy
    # delete relationship to any basket
    # basket's index page cache is already handled
    @topic = Topic.find(params[:id])
    index_for_basket = @topic.index_for_basket
    if !index_for_basket.nil?
      index_for_basket.update_index_topic('destroy')
    end

    zoom_destroy_and_redirect('Topic')
  end
end
