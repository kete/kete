# Include extensions into Rails components here

ActiveRecord::Base.send :include, RailsExtensions::ActiveRecord
