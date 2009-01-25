# using the faster xml parser (supposedly fastest)
# using nokogiri instead of libxml ruby gem now
require 'nokogiri'
require 'date'
require 'oai'
# reopen ZOOM::Record
# and create some data extraction methods
# based on the assumption of the record being oai_dc based
# as they are in Kete
# some extraction methods are specifically targeted
# at use with the oai gem as a oai pmh repository provider
# see Kete's included version of the oai gem for details
ZOOM::Record.class_eval do
  attr_accessor :doc, :root

  # return the id string, with no wrapping xml
  def oai_identifier
    @oai_identifier ||= complete_id.content
  end

  # returns fully formed oai_identifier from the record including wrapping xml
  def complete_id
    # complete_id = header.at("identifier").inner_xml
    complete_id = Nokogiri::XML(complete_header).at("identifier")
  end

  # returns fully formed oai_datestamp from the record
  # including wrapping xml
  def complete_datestamp
    # make sure we are in utc as per oai standard for datestamp
    # doing this for backwards compatibility
    # may pull out, may also need an "Z" at end, not sure
    # complete_datestamp = header.at("datestamp").inner_xml
    complete_datestamp = Nokogiri::XML(complete_header).at("datestamp")
  end

  def sets
    @sets = Array.new
    Nokogiri::XML(complete_header).xpath("setSpec").each { |set_spec| @sets << OAI::Set.new(:spec => set_spec.content) }
    @sets
  end

  # return the header as Nokogiri::XML::Element
  def header
    setup_for_being_parsed
    @header ||= @root.at(".//xmlns:header", @root.namespaces)
  end

  # return the header element as a string of the xml
  def complete_header
    header.to_s
  end

  # return the metadata as Nokogiri::XML::Element
  def metadata
    setup_for_being_parsed
    @metadata ||= @root.at(".//xmlns:metadata", @root.namespaces)
  end

  # return the metadata element as a string of the xml
  def complete_metadata
    metadata.to_s
  end

  # return only the oai_dc bit
  # without the wrapping metadata element
  # as Nokogiri::XML::Element
  def to_oai_dc
    @oai_dc ||= Nokogiri::XML(metadata.inner_html)
  end

  # we use to_complete_oai_dc for speed
  # when answering ListRecords
  # this is all aspects of the record
  # that are valid for oai_dc
  # record may have non-oai_dc, and that is not returned
  # returned as string of xml
  # should be faster to deal with tearing apart xml
  # and rebuilding it, rather than building it from scratch for the ActiveRecord model
  # at least in Kete
  def to_complete_oai_dc
    setup_for_being_parsed

    # we only want to return record/header and record/metadata
    # and dropped any other non-oai elements (Kete, i'm looking at you)
    # Kete includes non-oai schema in the record to other nifty things from within Kete
    complete_oai_dc = '<' + @root.name
    @root.namespaces.each { |k, v| complete_oai_dc += " #{k}=\"#{v}\"" }
    complete_oai_dc += '>'
    complete_oai_dc += complete_header
    complete_oai_dc += complete_metadata
    complete_oai_dc += '</' + @root.name + '>'

    complete_oai_dc
  end

  private

  # take the xml that is returned as a string from our ZOOM request for the record
  # and instantiate a new Nokogir::XML::Document as @doc
  # and set up @root as @doc's root Nokogir::XML::Element
  def setup_for_being_parsed
    @doc ||= Nokogiri::XML(xml)
    # sort of annoying, haven't found a way with nokogiri to set default namespace
    # so you don't have to specify it in searches
    # @root.register_default_namespace("oai")
    @root ||= @doc.root
  end
end
