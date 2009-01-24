# using the faster libxml parser (as compared to Rexml)
require 'nokogiri'
# require 'libxml'
require 'date'
# DEPRECIATED - using nokogiri instead of libxml ruby gem now
# leaving commented out old version of doing things for reference

# we extend the libxml node class
# to have some convenience methods
# require File.dirname(__FILE__) + "/libxml_helper"

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
    # complete_id = header.at("identifier").inner_xml
    complete_id = header.at("identifier")
  end

  # returns fully formed oai_datestamp from the record
  def complete_datestamp
    # make sure we are in utc as per oai standard for datestamp
    # doing this for backwards compatibility
    # may pull out, may also need an "Z" at end, not sure
    # complete_datestamp = header.at("datestamp").inner_xml
    complete_datestamp = header.at("datestamp")
  end

  def sets
    @sets = Array.new
    header.at("setSpec").to_a.each { |set_spec| @sets << OAI::Set.new(:spec => set_spec) }
  end

  def header
    setup_for_being_parsed
    # @header = @root.at("oai:header").to_s.to_libxml_doc.root
    @header ||= Nokogiri::XML(@root.at(".//xmlns:header", @root.namespaces).to_s)
  end

  # not entirely happy to have to do this stripping by a gsub
  # TODO: replace this with something that is included with Nokogiri
  def strip_xml_version(document_string)
    document_string.gsub("<?xml version=\"1.0\"?>", '')
  end

  def complete_header
    # pull out struct
    strip_xml_version(header.to_s)
  end

  def metadata
    @metadata ||= Nokogiri::XML(@root.at(".//xmlns:metadata", @root.namespaces).to_s)
  end

  def complete_metadata
    strip_xml_version(metadata.to_s)
  end

  def to_oai_dc
    setup_for_being_parsed
    # argh.  libxml can be a royal pain in the ass
    # when using xpath
    # kludge
    # using brittle hardcoding of array index!!!
    # oai_dc = @root.to_a[3]

    # nokogiri version is bit less brittle
    metdata.inner_html
  end

  # we use to_complete_oai_dc for speed
  # when answering ListRecords
  def to_complete_oai_dc
    setup_for_being_parsed
    # @root.to_s
    # we only want to return record/header and record/metadata
    # and dropped any other non-oai elements (Kete, i'm looking at you)
    # Kete includes non-oai schema in the record to other nifty things from within Kete

    complete_oai_dc = '<record'
    @root.namespaces.each { |k, v| complete_oai_dc += " #{k}=\"#{v}\"" }
    complete_oai_dc += '>'
    complete_oai_dc += complete_header
    complete_oai_dc += complete_metadata
    complete_oai_dc += "</record>"

    File.open(RAILS_ROOT + '/last.xml', 'w') { |f| f.write(complete_oai_dc)}

    complete_oai_dc
  end

  private

  def setup_for_being_parsed
    # xml is the record in raw xml (a string, though) as returned from our ZOOM call
    # @root = xml.to_libxml_doc.root
    @doc = Nokogiri::XML(xml)
    @root = @doc.root
    # sort of annoying, haven't found a way with nokogiri to set default namespace
    # so you don't have to specify it in searches
    # @root.register_default_namespace("oai")
  end
end
