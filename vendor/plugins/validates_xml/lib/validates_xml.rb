module ActiveRecord
  module Validations
    module ClassMethods
      def validates_xml(*attr_names)
        configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid], 
                          :on => :save, 
                          :with => nil }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
        validates_each(attr_names, configuration) do |record, attr_name, value|
          begin
            REXML::Document.new("<base>#{value}</base>")
          rescue REXML::ParseException => ex
            record.errors.add(attr_name, 
                              "is not valid xml.  #{ex.continued_exception}")
          end
        end
      end
    end   
  end
end