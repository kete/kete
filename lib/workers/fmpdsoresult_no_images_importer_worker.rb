require "importer"
# Imports Filemaker Pro's FMPDSORESULT format
# for importing topics without related images or anything
class FmpdsoresultNoImagesImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :fmpdsoresult_no_images_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  # do_work method is defined in Importer module
  def create(args = nil)
    importer_simple_setup
    @xml_path_to_record = "FMPDSORESULT/ROW"
  end
end
