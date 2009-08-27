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
  def doc
    @doc ||= Nokogiri::XML(xml)
  end

  def root
    @root ||= doc.root
  end

  # return the id string, with no wrapping xml
  def oai_identifier
    @oai_identifier ||= complete_id.content
  end

  # returns fully formed oai_identifier from the record including wrapping xml
  def complete_id
    @complete_id ||= header.at("identifier")
  end

  # returns fully formed oai_datestamp from the record
  # including wrapping xml
  def complete_datestamp
    # make sure we are in utc as per oai standard for datestamp
    # doing this for backwards compatibility
    # may pull out, may also need an "Z" at end, not sure
    # complete_datestamp = header.at("datestamp").inner_xml
    @complete_datestamp ||= header.at("datestamp")
  end

  def sets
    @sets = Array.new
    Nokogiri::XML(complete_header).xpath("setSpec").each { |set_spec| @sets << OAI::Set.new(:spec => set_spec.content) }
    @sets
  end

  # return the header as Nokogiri::XML::Element
  def header
    @header ||= root.at(".//xmlns:header", root.namespaces)
  end

  # return the header element as a string of the xml
  def complete_header
    @complete_header ||= header.to_s
  end

  # return the metadata as Nokogiri::XML::Element
  def metadata
    @metadata ||= root.at(".//xmlns:metadata", root.namespaces)
  end

  # return the metadata element as a string of the xml
  def complete_metadata
    @complete_metadata ||= metadata.to_s
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
    # we only want to return record/header and record/metadata
    # and dropped any other non-oai elements (Kete, i'm looking at you)
    # Kete includes non-oai schema in the record to other nifty things from within Kete
    complete_oai_dc = '<' + root.name
    root.namespaces.each { |k, v| complete_oai_dc += " #{k}=\"#{v}\"" }
    complete_oai_dc += '>'
    complete_oai_dc += complete_header
    complete_oai_dc += complete_metadata
    complete_oai_dc += '</' + root.name + '>'

    complete_oai_dc
  end
end
