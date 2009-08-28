class ZoomDb < ActiveRecord::Base
  include ConfigureZoomDbForSets

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

  # Create and return a zoom connection
  def open_connection
    zoom_options = { 'user' => zoom_user, 'password' => zoom_password }
    
    # enable unix socket connecting
    # this might make too many assumptions (i.e. using port as end to socket name)
    # TODO: maybe refactor
    c = ZOOM::Connection.new(zoom_options)
    if host.first == "/"
      unix_socket = 'unix:' + host + "-#{port}"
      c.connect(unix_socket)
    else
      c.connect(host, port.to_i)
    end

    c.database_name = database_name
    c
  end

  # hits up a zoom_db for results for a pqf_query
  # note that we we leave it up to the application to formulate
  # the query and they should match the syntax
  # of what the zoom_db expects
  # returns a zoom result set
  # will reuse already open connection, if optionally passed in
  def process_query(args = {})
    query = args[:query]

    conn = args[:existing_connection] || self.open_connection
    # we are always using xml at this point
    conn.preferred_record_syntax = 'XML'

    # do we want to retrieve the data
    # in a format other than the default?
    # corresponds to retrieve defined in zebra config
    # via an xslt file
    conn.element_set_name = args[:element_set_name] if args[:element_set_name]

    # not used by Kete, but others might find this useful
    conn.schema = args[:schema] if args[:schema]

    logger.info("query is #{query.to_s}, syntax XML")
    conn.search(query.to_s)
  end

  # get all zoom records that match a particular id
  # returns result set
  def records_identified_by(record_id, existing_connection = nil)
    process_query(:query => "@attr 1=12 @attr 4=3 \"#{record_id}\"", :existing_connection => existing_connection)
  end

  # Find whether a zoom record exists for this record in the given ZOOM database
  def has_zoom_record?(record_id, existing_connection = nil)
    records_identified_by(record_id, existing_connection).records.size > 0
  end

  # this takes a passed in record and deletes it from the zoom db
  def destroy_this(record, zoom_id, existing_connection = nil)
    c = existing_connection || open_connection
    p = c.package
    p.function = 'create'
    p.wait_action = 'waitIfPossible'
    # not compatible with latest zebra
    # p.syntax = 'no syntax'

    p.action = 'recordDelete'
    p.record = record unless record.nil?
    p.record_id_opaque = zoom_id unless zoom_id.nil?

    p.send('update')
    p.send('commit')
  end

  # this version of destroy doesn't require the record xml to be passed in
  # it gets it from zebra itself
  def destroy_identified_by(zoom_id, existing_connection = nil)
    existing_connection = existing_connection || open_connection

    # in theory there should only be one, but this handles duplicates
    results = records_identified_by(zoom_id, existing_connection)

    results.records.each do |record_xml|
      destroy_this(record_xml, zoom_id, existing_connection)
    end
  end

  # this takes a passed in record and saves it to the zoom db
  def save_this(record, zoom_id, existing_connection = nil)
    c = existing_connection || open_connection
    p = c.package
    p.function = 'create'
    p.wait_action = 'waitIfPossible'
    # not compatible with latest zebra
    # p.syntax = 'no syntax'

    p.action = 'specialUpdate'
    p.record = record unless record.nil?
    p.record_id_opaque = zoom_id unless zoom_id.nil?

    p.send('update')
    p.send('commit')
  end

  # used by active_scaffold, but may be handy somewhere else, too
  def to_label
    database_name
  end
end
