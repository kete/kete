module ArchiveUtilities
  unless included_modules.include? ArchiveUtilities
    # probably won't work on Windoze
    # good thing we don't officially support it!
    def decompress_under(target_directory)
      case content_type
      when 'application/zip', 'application/x-zip', 'application/x-zip-compressed'
        `unzip #{self.full_filename} -d #{target_directory}`
      when 'application/x-gtar', 'application/x-tar'
        `tar xf #{self.full_filename} #{target_directory}`
      when 'application/x-gzip', 'application/x-compressed-tar'
        if !self.filename.scan('tgz').blank? or !self.filename.scan("tar\.gz").blank?
          `tar xfz #{self.full_filename} -C #{target_directory}`
        else
          `cp #{self.full_filename} #{target_directory}; cd #{target_directory}; gunzip #{self.filename}`
        end
      end
    end
  end
end