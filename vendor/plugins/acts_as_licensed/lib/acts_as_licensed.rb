# ActsAsLicensed

require 'active_record'

module Katipo
  module Acts #:nodoc:
    module Licensed #:nodoc:

      def self.included(mod)
      	mod.class_eval do 
         	  extend(ClassMethods)
      	end
      end

      # declare the class level helper methods which
      # will load the relevant instance methods
      # defined below when invoked
      module ClassMethods
        def acts_as_licensed
          include Katipo::Acts::Licensed::InstanceMethods
          
          # Add association
          belongs_to :license
          
          # Add association to License class
          License.has_many self.table_name.to_sym, :dependent => :nullify
          
          # Tell ActsAsVersioned to ignore the license_id column (not versioned)
          self.non_versioned_columns << "license_id" if self.respond_to?(:non_versioned_columns)
        end
      end


      # Adds instance methods.
      module InstanceMethods
        
        # Returns license meta from License#metadata with replacement strings
        # replaced with values as per replacement equivalents hash.
        def license_metadata
          return nil if license.nil?
          
          # Hash for license metadata replacements
          # Replacement :key => 'value'
          replacements = {
            :license_url => license.url,
            :license_title => license.name,
            :license_image_url => license.image_url,
            :title => :title_for_license,
            :attribute_work_to_url => :author_url_for_license,
            :attribute_work_to_name => :author_for_license
          }
          
          # Use provided meta-data or a template to generate output
          if license.metadata.blank?
            
            # If there is no meta-data present, create some stub meta-data so the license is still
            # displayed.
            metadata_stub = "$$title$$ by <a href=\"$$attribute_work_to_url$$\">$$attribute_work_to_name$$</a> is <a rel=\"license\" href=\"$$license_url$$\">$$license_title$$</a>"
            
            # Only include the image segment if an image is present.
            metadata_stub = "<a rel=\"license\" href=\"$$license_url$$\"><img alt=\"$$license_title$$\" style=\"border-width:0\" src=\"$$license_image_url$$\" /></a><br />" + metadata_stub unless license.image_url.blank?
            
          else
            
            # Otherwise, use the supplied license meta-data.
            metadata_stub = license.metadata
          end
          
          # Replace keys with actual values as appropriate.
          signature = /(\${2}[a-zA-Z0-9\-\_]+\${2})/
          metadata_stub.gsub(signature) do |match|
            value = replacements[match.gsub(/\$/, '').to_sym]
            
            # If replacement value is a symbol, send the symbol to self
            # so as to raise errors when compulsory methods are not implemented.
            value.kind_of?(Symbol) ? send(value) : value
          end
        end
        
        # Check if the item has a license or not.
        def has_license?
          !license.nil?
        end
        
        def license_id=(*args)
          if !has_license?
            super(*args)
          else
            raise "You may not set license_id more than once"
            logger.info "Error: license_id was attempted to be set when already set."
          end
        end
        
      end

    end
  end
end

ActiveRecord::Base.send(:include, Katipo::Acts::Licensed) 
