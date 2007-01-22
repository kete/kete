module ConfigureActsAsZoomForKete
  # oai_record is a virtual attribute that holds the topic's entire content
  # as xml formated how we like it
  # for use by acts_as_zoom virtual_field_name, :raw => true
  # this virtual attribue will be populated/updated in our controller
  # in create and update
  # we also opt to explicitly call the zoom_save method ourselves
  # otherwise lots of attributes we need for the oai_record
  # aren't available
  unless included_modules.include? ConfigureActsAsZoomForKete
    attr_accessor :oai_record
    attr_accessor :basket_urlified_name
    def self.included(klass)
      klass.send :acts_as_zoom, :fields => [:oai_record], :save_to_public_zoom => ['localhost', 'public'], :raw => true, :additional_zoom_id_attribute => :basket_urlified_name, :use_save_callback => false
    end
  end
end
