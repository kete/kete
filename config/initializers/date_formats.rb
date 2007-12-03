# date styles:
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
    :date => "%Y-%m-%d",
    :presentable_datetime => "%a %b %d, %Y %H:%M",
    :filename_datetime => "%Y-%m-%d-%H-%M",
    :euro_date => "%d/%m/%Y",
    :euro_date_time => "%d/%m/%Y %H:%M"
)
