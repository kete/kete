class ExtendedFieldsController < ApplicationController

  helper ExtendedFieldsHelper

  # everything else is handled by application.rb
  before_filter :login_required, only: [:list, :index, :add_field_to_multiples, :fetch_subchoices, :fetch_topics_from_topic_type, :validate_topic_type_entry ]

  before_filter :set_page_title

  permit "site_admin or admin of :site or tech_admin of :site",
          except: [ :add_field_to_multiples, :fetch_subchoices, :fetch_topics_from_topic_type, :validate_topic_type_entry ]

  active_scaffold :extended_field do |config|
    # Default columns and column exclusions
    config.columns = [:label, :description, :xml_element_name, :ftype, :import_synonyms, :example, :multiple, :user_choice_addition, :link_choice_values]
    config.list.columns.exclude [:updated_at, :created_at, :topic_type_id, :xsi_type, :user_choice_addition, :link_choice_values]

    config.columns[:description].options = { rows: 4, cols: 50 }

    config.columns[:import_synonyms].description = I18n.t('extended_fields_controller.import_synonyms_description')
    config.columns[:import_synonyms].options = { rows: 4, cols: 50 }

    config.columns << [:base_url]
    config.columns[:base_url].label = I18n.t('extended_fields_controller.base_url')
    config.columns[:base_url].description = I18n.t('extended_fields_controller.base_url_description')

    # CRUD for adding/removing choices
    config.columns << [:pseudo_choices]
    config.columns[:pseudo_choices].label = I18n.t('extended_fields_controller.available_choices')
    config.columns[:pseudo_choices].description = I18n.t('extended_fields_controller.available_choices_description')
    config.columns[:user_choice_addition].label = ''
    config.columns[:link_choice_values].label = ''

    config.columns << [:topic_type]
    config.columns[:topic_type].label = I18n.t('extended_fields_controller.topic_type_choices')
    config.columns[:topic_type].description = I18n.t('extended_fields_controller.topic_type_choices_description')

    config.columns << [:circa]
    config.columns[:circa].label = I18n.t('extended_fields_controller.circa')
    config.columns[:circa].description = I18n.t('extended_fields_controller.circa_description')
  end

  def add_field_to_multiples
    @extended_field = ExtendedField.find(params[:extended_field_id])
    @n = params[:n].to_i
    @item_type_for_params = params[:item_key]

    respond_to do |format|
      format.js
    end
  end

  # Fetch subchoices for a choice.
  def fetch_subchoices

    extended_field = ExtendedField.find(params[:options][:extended_field_id])

    # Find the current choice
    current_choice = extended_field.choices.matching(params[:label], params[:value])

    blank_value = params[:label].blank? && params[:value].blank?

    choices = current_choice ? current_choice.children : []

    choices = choices.reject { |c| !extended_field.choices.member?(c) }

    options = {
      choices: choices,
      level: params[:for_level].to_i + 1,
      extended_field: extended_field
    }

    # Ensure we have a standard environment to work with. Some parts of the helpers (esp. ID and NAME
    # attribute generation rely on these.
    @item_type_for_params = params[:item_type_for_params]
    @field_multiple_id = params[:field_multiple_id]


    render :update do |page|

      # Generate the DOM ID
      dom_id = "#{id_for_extended_field(options[:extended_field])}__level_#{params[:for_level]}"

      if blank_value || (options[:choices].blank? && !extended_field.user_choice_addition?)
        page.replace_html dom_id, ""
      else
        page.replace_html dom_id,
          partial: "extended_fields/choice_#{params[:editor]}_editor",
          locals: params[:options].merge(options)
      end
    end
  end

  def fetch_topics_from_topic_type
    begin
      extended_field = ExtendedField.find(params[:extended_field_id])
      parent_topic_type = extended_field.topic_type.to_i
      extended_field_key = @template.send(:id_for_extended_field, extended_field).gsub('_extended_content_values_', '').gsub(/_$/, '')
      logger.debug("What is extended_field_key: #{extended_field_key}")
      search_term = params[params[:extended_field_for]][:extended_content_values][extended_field_key]
      if extended_field.multiple?
        multiple_id = params[:multiple_id] || 1
        search_term = search_term[multiple_id]
      end
    rescue
      raise "Something went wrong getting the extended field, it's parent topic type or the users search term"
    end

    search_term = search_term.split(' (').first if search_term =~ /.+ \(.+\)/
    logger.debug("What is search term: #{search_term}")

    topic_type_ids = TopicType.where(id: parent_topic_type).full_set.collect { |a| a.id } rescue []

    topics = Topic.where("title LIKE ? AND topic_type_id IN (?)", "%#{search_term}%", topic_type_ids).order("title ASC").limit(10)
    logger.debug("Topics are: #{topics.inspect}")

    topics = topics.map { |entry|
      @template.content_tag("li", "#{entry.title.sanitize} (#{@template.url_for(urlified_name: entry.basket.urlified_name,
                                                                          controller: 'topics',
                                                                          action: 'show',
                                                                          id: entry,
                                                                          only_path: false).sub("/#{I18n.locale}/", '/')})")
    }
    render inline: @template.content_tag("ul", topics.uniq)
  end

  def validate_topic_type_entry
    extended_field = ExtendedField.find(params[:extended_field_id])
    parent_topic_type = TopicType.find(extended_field.topic_type.to_i)
    value, field_id = params[:value], params[:field_id]

    no_value_js = "$('#{field_id}_valid').hide(); $('#{field_id}_invalid').hide();"
    valid_value_js = "$('#{field_id}_valid').show(); $('#{field_id}_invalid').hide();"
    invalid_value_js = "$('#{field_id}_valid').hide(); $('#{field_id}_invalid').show();"

    js = no_value_js
    unless value.blank?
      js = invalid_value_js
      topic = Topic.where(id: value.split('/').last.to_i).select('topic_type_id')
      if topic
        valid_topic_type_ids = parent_topic_type.full_set.collect { |topic_type| topic_type.id }
        js = valid_value_js if valid_topic_type_ids.include?(topic.topic_type_id)
      end
    end

    respond_to do |format|
      format.js do
        render text: js, layout: false
      end
    end
  end

  private

  def base_url_form_column(record, input_name)
    value = record.id.nil? ? '' : record.base_url
    @template.text_field_tag(input_name, value, { id: 'record_base_url' })
  end
  helper_method :base_url_form_column

  def set_page_title
    @title = t('extended_fields_controller.title')
  end
end
