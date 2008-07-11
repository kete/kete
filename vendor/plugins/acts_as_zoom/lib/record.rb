# using the faster libxml parser (as compared to Rexml)
require 'libxml'
require 'date'
# we extend the libxml node class
# to have some convenience methods
require File.dirname(__FILE__) + "/libxml_helper"

require 'oai'
# reopen ZOOM::Record and alias to_oai to xml
# xml record normally returns record verbatim
# if it is already in xml
# in Kete's use of acts_as_zoom this is true
# putting use of it here because it might be useful to other apps
# handy when using oai gem to create an OAI-PMH Repository!
ZOOM::Record.class_eval do

  # returns fully formed oai_identifier from the record
  def complete_id
    complete_id = header.at("identifier").inner_xml
  end

  # returns fully formed oai_datestamp from the record
  def complete_datestamp
    # make sure we are in utc as per oai standard for datestamp
    # doing this for backwards compatibility
    # may pull out, may also need an "Z" at end, not sure
    complete_datestamp = header.at("datestamp").inner_xml
  end

  def sets
    @sets = Array.new
    header.at("setSpec").to_a.each { |set_spec| @sets << OAI::Set.new(:spec => set_spec) }
  end

  def header
    setup_for_being_parsed
    @header = @root.at("oai:header").to_s.to_libxml_doc.root
  end

  def complete_header
    header.to_s
  end

  def to_oai_dc
    setup_for_being_parsed
    # argh.  libxml can be a royal pain in the ass
    # when using xpath
    # kludge
    # using brittle hardcoding of array index!!!
    oai_dc = @root.to_a[3]
  end

  # we use to_complete_oai_dc for speed
  # when answering ListRecords
  def to_complete_oai_dc
    setup_for_being_parsed
    @root.to_s
  end

  private

  def setup_for_being_parsed
    @root = xml.to_libxml_doc.root
    @root.register_default_namespace("oai")
  end
end
