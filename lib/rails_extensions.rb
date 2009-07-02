module RailsExtensions
  unless included_modules.include? RailsExtensions

    module ActiveRecord

      def class_as_key
        # self. is necessary in this case because class is a reserved word
        self.class.name.tableize.singularize.to_sym
      end

    end

  end
end
