# TODO: put in license and copyright

require 'active_record'
require 'rexml/document'
# this is how we talk to a Z39.50 server
# like zebra or voyager
# if you get missing source file errors
# do "which ruby"
# chances are that you have more than one ruby
# and your env has the wrong one being selected to use
# or
# specify the complete path to zoom
# here's an alternative path that works with Macports
# on Mac OS X
# require '/opt/local/lib/ruby/site_ruby/1.8/powerpc-darwin8.8.0/zoom.bundle'
require 'zoom'
# our model for storing Z39.50 server connection information
require 'zoom_db'

module ZoomMixin
  module Acts #:nodoc:
    module ARZoom #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        include ZoomMixin

        def get_field_value(field)
          fields_for_zoom << field
          define_method("#{field}_for_zoom".to_sym) do
            begin
              value = self[field] || self.instance_variable_get("@#{field.to_s}".to_sym) || self.method(field).call
            rescue
              value = ''
              logger.debug "There was a problem getting the value for the field '#{field}': #{$!}"
            end
          end
        end

        def acts_as_zoom(options={})
          configuration = {
            :fields => nil,
            :raw => false,
            :save_to_public_zoom => nil,
            :save_to_private_zoom => nil,
            :additional_zoom_id_attribute => nil,
            :use_save_callback => true
          }

          # we need at least save_to_public_zoom to have an array of :host and :database
          configuration.update(options) if options.is_a?(Hash)

          if configuration[:use_save_callback]

            class_eval <<-CLE
              include ZoomMixin::Acts::ARZoom::InstanceMethods

              after_save    :zoom_save
              after_destroy :zoom_destroy

              cattr_accessor :fields_for_zoom
              cattr_accessor :configuration

              @@fields_for_zoom = Array.new
              @@configuration = configuration

              if configuration[:fields].respond_to?(:each)
                configuration[:fields].each do |field|
                  get_field_value(field)
                end
              else
                @@fields_for_zoom = nil
              end
            CLE
          else
            # the model opts out of automatic
            # after_save    :zoom_save
            # and will call the zoom_save method explicitly
            # probably in the controller
            class_eval <<-CLE
              include ZoomMixin::Acts::ARZoom::InstanceMethods

              after_destroy :zoom_destroy

              cattr_accessor :fields_for_zoom
              cattr_accessor :configuration

              @@fields_for_zoom = Array.new
              @@configuration = configuration

              if configuration[:fields].respond_to?(:each)
                configuration[:fields].each do |field|
                  get_field_value(field)
                end
              else
                @@fields_for_zoom = nil
              end
            CLE

          end

        end

        # operate on zoom result set which then can have the following done to it:
        # see http://ruby-zoom.rubyforge.org/xhtml/ch04.html

        # given a zoom result set
        # and optionally start and end record range
        # returns zoom records
        def records_from_zoom_result_set(options={})
          logger.debug("inside records_from_zoom_result_set")
          rset = options[:result_set]

          records = ''
          if options[:start_record].nil?
            records = rset.records
          else
            records = rset[options[:start_record]..options[:end_record]]
          end

          return records
        end

        # collect the ids of the records
        def ids_from_zoom_result_set(options={})

          rset = options[:result_set]
          ids = Array.new

          # by having this match the end of the line
          # from the last colon, it is not necessary
          # to pull out the ZoomDb.zoom_id_stub first
          re = Regexp.new("([^:]+)$")

          records = ''

          if options[:start_record].nil?
            records = records_from_zoom_result_set(:result_set => rset)
          else
            records = records_from_zoom_result_set(:result_set => rset,
                                                   :start_record => options[:start_record],
                                                   :end_record => options[:end_record])
          end

          records.each do |record|
            # walk through nested elements to find our zoom_id
            temp_hash = Hash.from_xml(record.xml)
            array_of_path_up_to_element = ZoomDb.zoom_id_xml_path_up_to_element.split("/")

            array_of_path_up_to_element.each do |container|
              temp_hash = temp_hash[container] unless container.empty?
            end


            zoom_id = temp_hash[ZoomDb.zoom_id_element_name]
            record_id = zoom_id.match re
            record_id = record_id.to_s
            ids << record_id.to_i
            return ids
          end
        end

        # processes a passed in query
        # returns matching objects in our model
        def find_by_zoom(options={})
          # expects :query or :pqf_query
          # and :zoom_db
          rset = process_query(options)
          if rset.size > 0
            ids = ids_from_zoom_result_set(:result_set => rset)
            conditions = [ "#{self.table_name}.id in (?)", ids ]
            result = self.find(:all, :conditions => conditions)
          else
            return ""
          end
        end

        # takes in an existing zoom result set
        # optionally a start and end record range
        # returns matching objects in our model
        def find_by_zoom_result_set(options={})
          # expects to be passed an existing :result_set object
          # :start_record
          # and :end_record
          rset = options[:result_set]
          if rset.size > 0
            ids = Array.new
            if options[:start_record].nil?
              ids = ids_from_zoom_result_set(:result_set => rset)
            else
              ids = ids_from_zoom_result_set(:result_set => rset,
                                             :start_record => options[:start_record],
                                             :end_record => options[:end_record])
            end

            conditions = [ "#{self.table_name}.id in (?)", ids ]
            result = self.find(:all, :conditions => conditions)
          else
            return ""
          end
        end

        # Rebuilds the Zoom index
        def rebuild_zoom_index
          self.find(:all).each {|content| content.zoom_save}
          logger.debug self.count>0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"
        end

        # hits up a zoom_db for results for a pqf_query
        # note that we we leave it up to the application to formulate
        # the query and they should match the syntax
        # of what the zoom_db expects
        # returns a zoom result set
        def process_query(args = {})
          zoom_db = args[:zoom_db]
          query = args[:query]

          options = {}

          hostname, port = zoom_db.host, zoom_db.port.to_i
          options['user'] = zoom_db.zoom_user
          options['password'] = zoom_db.zoom_password

          conn = ZOOM::Connection.new(options).connect(hostname, port)
          conn.database_name = zoom_db.database_name
          # we are always using xml at this point
          conn.preferred_record_syntax = 'XML'

          logger.info("query is #{query.to_s}, syntax XML")
          conn.search(query.to_s)
        end

        def split_to_search_terms(query)
          # based on http://jystewart.net/process/archives/2006/10/splitting-search-terms
          # return an array of terms either words or phrases
          # Find all phrases enclosed in quotes and pull
          # them into a flat array of phrases
          query = query.to_s
          double_phrases = query.scan(/"(.*?)"/).flatten
          single_phrases = query.scan(/'(.*?)'/).flatten

          # Remove those phrases from the original string
          left_over = query.gsub(/"(.*?)"/, "").squeeze(" ").strip
          left_over = left_over.gsub(/'(.*?)'/, "").squeeze(" ").strip

          # Break up the remaining keywords on whitespace
          keywords = left_over.split(/ /)

          keywords + double_phrases + single_phrases
        end
      end

      module InstanceMethods
        include ZoomMixin

        def zoom_id
          # assumes that the Z39.50 on the other end uses same format for recordId
          # as we we have
          # seems like a safe assumption, seeing as we have write perm on the Z39.50 server
          # you may have to adjust for your needs
          # this form of recordId also assumes that Class:id is unique in the Z39.50 server
          # thus limiting the Z39.50 database to one rails app
          # it's pretty trivial to set up an additional Z39.50 db, so this seems reasonable
          zoom_id = ""
          if !ZoomDb.zoom_id_stub.blank?
            zoom_id = ZoomDb.zoom_id_stub
          end
          if !configuration[:additional_zoom_id_attribute].blank?
            field = configuration[:additional_zoom_id_attribute]
            value = self[field] || self.instance_variable_get("@#{field.to_s}".to_sym) || self.method(field).call
            zoom_id += value.to_s
            zoom_id += ":"
          end
          zoom_id += "#{self.class.name}:#{self.id}"
        end

        def zoom_choose_zoom_db
          begin
            public_zoom = configuration[:save_to_public_zoom]
            private_zoom = configuration[:save_to_private_zoom]

            # what is the correct server?
            zoom_db_data = Hash.new

            # public by default
            if public_zoom
              zoom_db_data = { :db_host => public_zoom[0], :db_name => public_zoom[1] }
            end

            # even if we have a private zoom db, the object might be public
            if private_zoom
              # check whether this is a private object
              if self.private?
                zoom_db_data = { :db_host => private_zoom[0], :db_name => private_zoom[1] }
              end
            end

            zoom_db = ZoomDb.find_by_host_and_database_name(zoom_db_data[:db_host],zoom_db_data[:db_name])

            return zoom_db

          rescue
            logger.error "Couldn't get any zoom_db configuration parameters."
            false
          end
        end

        def zoom_prepare_record
          zoom_record = ''
          # raw?
          if configuration[:raw]
            # assumes only a single field, as noted in the README
            fields_for_zoom.each do |field|
              value = self.send("#{field}_for_zoom")
              zoom_record = value.to_s
            end
          else
            zoom_record = to_zoom_record.to_s
          end
          return zoom_record
        end

        # saves to the appropriate ZoomDb based on configuration
        def zoom_save
          logger.debug "zoom_save: #{zoom_id}"

          zoom_record = self.zoom_prepare_record

          # get the correct zoom database connection parameters
          zoom_db = self.zoom_choose_zoom_db

          # here's where we actually add/replace the record on the zoom server
          # specialUpdate will insert if no record exists, or replace if one does

          # ruby-zoom extended services
          zoom_options = { 'user' => zoom_db.zoom_user, 'password' => zoom_db.zoom_password }

          c = ZOOM::Connection.new(zoom_options).connect(zoom_db.host, zoom_db.port.to_i)
          c.database_name = zoom_db.database_name
          p = c.package
          p.function = 'create'
          p.wait_action = 'waitIfPossible'
          p.syntax = 'no syntax'

          p.action = 'specialUpdate'
          p.record = zoom_record
          p.record_id_opaque = zoom_id

          p.send('update')
          p.send('commit')

          true
        end

        def zoom_destroy
          logger.debug "zoom_destroy: #{self.class.name} : #{self.id}"

          # need to pass in whole record as well as zoom_id, even though it's a delete
          zoom_record = self.zoom_prepare_record

          # get the correct zoom database connection parameters
          zoom_db = self.zoom_choose_zoom_db

          # testing ruby-zoom extended services
          zoom_options = { 'user' => zoom_db.zoom_user, 'password' => zoom_db.zoom_password }

          c = ZOOM::Connection.new(zoom_options).connect(zoom_db.host, zoom_db.port.to_i)
          c.database_name = zoom_db.database_name
          p = c.package
          p.function = 'create'
          p.wait_action = 'waitIfPossible'
          p.syntax = 'no syntax'

          p.action = 'recordDelete'
          p.record = zoom_record
          p.record_id_opaque = zoom_id

          p.send('update')
          p.send('commit')

          true
        end

        # TODO: check this properly converts records to zoom record
        def to_zoom_record
          logger.debug "to_zoom_record: creating record for class: #{self.class.name}, id: #{self.id}"
          record = REXML::Element.new('record')

          # Zoom id is <ZoomDb.zoom_id_stub><classname>:<id> to be unique across all models

          # assumes that you have ZoomDb.zoom_id_element_name mapped to record id on your Z39.50 server
          # server, most likely zebra
          # our inserts, updates, and deletes will break if this isn't set up correctly
          id_field = ZoomDb.zoom_id_element_name
          record.add_element field(id_field, zoom_id)

          # iterate through the fields and add them to the document,
          default = ""
          unless fields_for_zoom
            self.attributes.each_pair do |key,value|
              record.add_element field("#{key}", value.to_s) unless key.to_s == "id"
              default << "#{value.to_s} "
            end
          else
            fields_for_zoom.each do |field|
              value = self.send("#{field}_for_zoom")
              record.add_element field("#{field}", value.to_s)
              default << "#{value.to_s} "
            end
          end
          logger.debug record
          return record
        end

        def field(name, value)
          field = REXML::Element.new("#{name}")
          field.add_text(value)
          field
        end

      end
    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it
ActiveRecord::Base.class_eval do
  include ZoomMixin::Acts::ARZoom
end
