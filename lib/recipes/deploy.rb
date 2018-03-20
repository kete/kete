# frozen_string_literal: true

# general capistrano recipes to restart application server

namespace :deploy do
  desc 'Start Application Server'
  task :start do
    set_app_server
    case app_server
    when :apache
      deploy.apache.start
    when :mongrel
      deploy.mongrel.start
    end
  end

  desc 'Stop Application Server'
  task :stop do
    set_app_server
    case app_server
    when :apache
      deploy.apache.stop
    when :mongrel
      deploy.mongrel.stop
    end
  end

  desc 'Restart Application Server'
  task :restart do
    set_app_server
    case app_server
    when :apache
      deploy.apache.restart_app
    when :mongrel
      deploy.mongrel.restart
    end
  end

  def set_app_server
    begin; app_server; rescue; set(:app_server, :apache); end
    raise "Unknown Application Server #{app_server}" unless %i[apache mongrel].include?(app_server)
  end
end
