class ZoomDb < ActiveRecord::Base
  validates_presence_of :database_name, :host, :port
  validates_uniqueness_of :database_name, :scope => [:host, :port], :message => "The combination of database name, host, and port must be unique."
  validates_numericality_of :port

end
