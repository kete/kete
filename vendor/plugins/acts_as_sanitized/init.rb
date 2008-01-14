require 'acts_as_sanitized'
ActiveRecord::Base.send(:include, AlexPayne::Acts::Sanitized)
