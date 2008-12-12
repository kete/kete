def set_constant(constant, value)
  if respond_to?(:silence_warnings)
    silence_warnings do
      Object.send(:remove_const, constant) if Object.const_defined?(constant)
      Object.const_set(constant, value)
    end
  else
    Object.send(:remove_const, constant) if Object.const_defined?(constant)
    Object.const_set(constant, value)
  end
end

def ensure_zebra_running
  begin
    zoom_db = ZoomDb.find_by_database_name('public')
    Topic.process_query(:zoom_db => zoom_db, :query => "@attr 1=_ALLRECORDS @attr 2=103 ''")
  rescue
    start_zebra = system('rake zebra:start')
    unless start_zebra
      raise "Zebra unable to start. Please start it manually before rerunning the tests."
    end
  end
end
