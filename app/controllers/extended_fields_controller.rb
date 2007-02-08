class ExtendedFieldsController < ApplicationController
  permit "site_admin or admin of :current_basket"

  ajax_scaffold :extended_field
end
