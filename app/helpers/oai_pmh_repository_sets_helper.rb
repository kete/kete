module OaiPmhRepositorySetsHelper
  def zoom_db_column(record)
    link_to(record.zoom_db.database_name,
            controller: 'zoom_dbs',
            urlified_name: @site_basket.urlified_name,
            action: 'show',
            id: record.zoom_db)
  end
end
