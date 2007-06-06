class ZoomDb < ActiveRecord::Base
  # we use this virtual attribute to store what should proceed ClassName:Id in zoom_id
  cattr_accessor :zoom_id_stub
  # what is the name of the xml element for our records
  cattr_accessor :zoom_id_element_name
  # what is the xml path to the record element
  # for simple cases (where you are using to_zoom_record for example)
  # this is likely just plain "record/", note no preceding / from root
  cattr_accessor :zoom_id_xml_path_up_to_element

  validates_presence_of :database_name, :host, :port
  validates_uniqueness_of :database_name, :scope => [:host, :port], :message => "The combination of database name, host, and port must be unique."
  validates_numericality_of :port

end
