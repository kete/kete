# reopen ZOOM::ResultSet
# and create some convenience methods
ZOOM::ResultSet.class_eval do
  # add some logic to handle common cases
  # i.e. all records up to end record
  # or starting at an offset
  def records_from(options)
    if options[:start_record].nil?
      @records_from = records
    else
      @records_from = self[options[:start_record]..options[:end_record]]
    end
    @records_from
  end
end
