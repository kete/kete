class ZoomDbsController < ApplicationController
  permit "site_admin or admin of :current_basket"

  ajax_scaffold :zoom_db
end
