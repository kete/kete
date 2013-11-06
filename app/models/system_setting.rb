class SystemSetting < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 255

  def self.find_by_name(name)
    first(:conditions => ["name = ?", name.to_s]) unless name.nil?
  end

  def self.[](name)
    return unless name
    setting = find_by_name(name)
    setting.value if setting
  end

  def to_f
    value.to_f
  end

  def to_i
    value.to_i
  end

  def to_s
    value
  end

  def constant_name
    name.upcase.gsub(/[^A-Z0-9\s_-]+/,'').gsub(/[\s-]+/,'_')
  end

  def constant_value
    return value.to_i if Integer(value) rescue false
    return value.to_f if Float(value) rescue false
    return true if value == "true"
    return false if value == "false"
  end

  def self.method_missing(m, *args, &block)  
    # SystemSetting.pretty_print -> SystemSetting.find_by_name("Pretty Print").value
    # SystemSetting.is_configured? -> SystemSetting.find_by_name("Is Configured").value

    m =~ /^(.*?)\??$/
    name = $1.titleize

    if setting = SystemSetting.find_by_name(name)
      return setting.constant_value
    else
      raise "unknown method: SystemSetting.#{m}"
    end
  end


  #def self.is_configured?
  #end

  #def self.pretty_site_name
  #  self.pretty_site_name
  #end
end


class SystemSetting::Defaults
  def is_configured
    false
  end

  # we have to load meaningless default values for any constant used in our models
  # since otherwise things like migrations will fail, before we bootstrap the db
  # these will be set up with system settings after rake db:bootstrap
  def maximum_uploaded_file_size
    50.megabyte 
  end

  def image_sizes 
    {:small_sq => '50x50!', :small => '50', :medium => '200>', :large => '400>'} 
  end

  def audio_content_types
    ['audio/mpeg']
  end

  def document_content_types
    ['text/html']
  end

  def enable_converting_documents
    false
  end

  def enable_embedded_support
    false
  end

  def image_content_types
    [:image]
  end

  def video_content_types
    ['video/mpeg']
  end

  def site_url
    "kete.net.nz"
  end

  def notifier_email
    "kete@library.org.nz"
  end

  def default_baskets_ids
    [1]
  end

  def no_public_version_title
    ""
  end

  def blank_title
    ""
  end
end


