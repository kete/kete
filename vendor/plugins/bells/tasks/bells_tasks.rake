class Mylogger # Adapted from Capistrano's logger class
  
  attr_accessor :level

  IMPORTANT = 0
  INFO      = 1
  DEBUG     = 2
  TRACE     = 3
  
  MAX_LEVEL = 3
  
  def initialize
    @level = 0
  end
  
  def log(level, message, line_prefix=nil)
    indent = "%*s" % [MAX_LEVEL, "*" * (MAX_LEVEL - level)] + " - #{message}"
    puts indent
  end

  def info(message, line_prefix=nil)
    log(INFO, message, line_prefix)
  end
end

# require 'highline'

namespace :bells do

  desc 'Installs required files to lib/recipes directory.'
  task :install do
    logger = Mylogger.new
    
    if File.file? "Capfile"
      logger.info "Backing up old Capfile..."
      FileUtils.copy("Capfile", "Capfile.old")
    end
    
    logger.info "Creating Capfile..."
    capfile = File.read(File.dirname(__FILE__) + '/../' + "/recipes/templates/Capfile")
    File.open("Capfile", File::WRONLY|File::CREAT) { |f| f.puts capfile }
    
    # Copies recipes to lib/recipes
    logger.info "Creating recipes folder..."
    unless File.directory? "lib/recipes"
      FileUtils.mkdir 'lib/recipes'
    end
    %w(apache mysql mint mongrel deploy php tools).each do |file|
      logger.info "Adding #{file}..."
      FileUtils.cp File.dirname(__FILE__) + '/../' + "/recipes/#{file}.rb", RAILS_ROOT + "/lib/recipes/"
    end
    
    logger.info "Displaying tasks."
    system "cap -T"
  end
    
  desc "Removes files installed by Bells."
  task :uninstall do
    # Copies recipes to lib/recipes
    FileUtils.rm_rf "lib/recipes"
    if File.file? "Capfile.old"
      FileUtils.rm "Capfile"
      FileUtils.mv("Capfile.old", "Capfile")
    end
  end
  
  desc "Updates Bells recipes"
  task :update do
    logger = Mylogger.new
    raise "No recipes file found!" unless File.directory? "lib/recipes"
    %w(apache mysql mint mongrel deploy php tools).each do |file|
      logger.info "Updating #{file} recipe."
      FileUtils.rm RAILS_ROOT + "/lib/recipes/#{file}.rb"
      FileUtils.cp File.dirname(__FILE__) + '/../' + "/recipes/#{file}.rb", RAILS_ROOT + "/lib/recipes/"
    end
  end
end