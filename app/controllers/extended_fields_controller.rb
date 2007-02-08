class ExtendedFieldsController < ApplicationController
  permit "site_admin of :current_basket"
    
  ajax_scaffold :extended_field
end
