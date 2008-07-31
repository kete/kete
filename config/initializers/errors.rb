# making the attachment_fu upload file error more helpful
ActiveRecord::Errors.default_error_messages[:inclusion] += '.  Are you sure entered the right type of file for what you wanted to upload?  For example, a .jpg for an image.'
