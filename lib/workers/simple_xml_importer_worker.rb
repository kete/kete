require "importer"
# generic simple topic importer
# must have xml_to_record_path specified
# in the Import object
# uses the default Importer methods
class SimpleXmlImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :simple_xml_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  # do_work method is defined in Importer module
  def create(args = nil)
    importer_simple_setup
  end
end
