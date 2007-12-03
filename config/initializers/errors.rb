# For handling pre controller errors
# see http://wiki.rubyonrails.org/rails/pages/HandlingPreControllerErrors
require 'error_handler_basic' # defines AC::Base#rescue_action_in_public

# making the attachment_fu upload file error more helpful
ActiveRecord::Errors.default_error_messages[:inclusion] += '.  Are you sure entered the right type of file for what you wanted to upload?  For example, a .jpg for an image.'

