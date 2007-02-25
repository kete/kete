class Pp4ExtractController < ApplicationController

  def index

  end
  
  #import for archives
  def import
    begin
      content_item_hash = Hash.new
      file_path = "/home/bob/archives2.xml"

      xml_file = File.open(file_path,"r") rescue abort("cant open %s" % file_path)

      content_hash = Hash.from_xml(xml_file)

      # logger.debug(content_hash["Root"]["Information"]["Record"][0].to_s)
      x=0
      content_hash["Root"]["Information"]["Record"].each do |item|
        logger.warn("item#{x}")
	# content_item_hash["topic"] = item
	content_item_hash["topic_type"] = 'Organisation'
	content_item_hash["topic"] = { "topic_type_id" => '5', 
	                                "description" => item["DESCRIP"],
					"short_summary" => item["ADMIN"],
					"title" => item["TITLE"],
					"basket" => 1,
					"tag_list" => "#{item["EARLYDATE"]},#{item["LATEDATE"]}"
				      }
	logger.debug(content_item_hash.to_s)
	x = x+ 1
       
        topic_type = TopicType.find(5)
	@fields = topic_type.topic_type_to_field_mappings
	@ancestors = TopicType.find(topic_type).ancestors
	
	if @ancestors.size > 1
	  @ancestors.each do |ancestor|
          @fields = @fields + ancestor.topic_type_to_field_mappings
        end
        
	if @fields.size > 0
          extended_fields_update_hash_for_item(:fields => @fields, :item_key => 'topic')
        end

        replacement_topic_hash = extended_fields_replacement_params_hash(:item_key => 'topic', :item_class => 'Topic')

        @topic = Topic.new(replacement_topic_hash)
        @successful = @topic.save

        @topic.creators << current_user
      end
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    if @successful
      prepare_and_save_to_zoom(@topic)
      flash[:notice] = 'Creation was successfully.'
      redirect_to :action => 'index'
    else
      flash[:notice] = 'Creation failed.' 
      redirect_to :action => 'index'	
    end
  end

  def list
  end

end














