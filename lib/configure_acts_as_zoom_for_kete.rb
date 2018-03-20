# frozen_string_literal: true
# module ConfigureActsAsZoomForKete
#   # oai_record is a virtual attribute that holds the topic's entire content
#   # as xml formated how we like it
#   # for use by acts_as_zoom virtual_field_name, :raw => true
#   # this virtual attribue will be populated/updated in our controller
#   # in create and update
#   # we also opt to explicitly call the zoom_save method ourselves
#   # otherwise lots of attributes we need for the oai_record
#   # aren't available
#   unless included_modules.include? ConfigureActsAsZoomForKete
#     def self.included(klass)
#       klass.send :include, OaiZoom
#
#       klass.send :acts_as_zoom, :fields => [:oai_record],
#                                 :save_to_public_zoom => ['public'],
#                                 :save_to_private_zoom => ['private'],
#                                 :raw => true,
#                                 :additional_zoom_id_attribute => :basket_urlified_name,
#                                 :use_save_callback => false
#
#     end
#
#     def oai_record
#       @oai_record ||= oai_record_xml
#     rescue
#       logger.error("oai_record gen error: #{$!.to_s}")
#     end
#
#     def basket_urlified_name
#       @basket_urlfied_name ||= basket.urlified_name
#     end
#
#   end
# end
