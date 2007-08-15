#!/usr/bin/env ruby

# Save this somewhere, chmod 755 it, then add
#   complete -C path/to/this/script -o default cap
# to your ~/.bashrc
#
# If you update your tasks, just $ rm ~/.captabs*
#
# Adapted from 
# http://onrails.org/articles/2006/08/30/namespaces-and-rake-command-completion

exit 0 unless File.file?(File.join(Dir.pwd, 'config', 'deploy.rb'))
exit 0 unless /^cap\b/ =~ ENV["COMP_LINE"]

def cap_tasks
  if File.exists?(dotcache = File.join(File.expand_path('~'), ".captabs-#{Dir.pwd.hash}"))
    File.read(dotcache)
  else
    tasks = `cap -T|grep "^cap"|cut -d " " -f 2`
    File.open(dotcache, 'w') { |f| f.puts tasks }
    tasks
  end
end

after_match = $'
task_match = (after_match.empty? || after_match =~ /\s$/) ? nil : after_match.split.last
tasks = cap_tasks.split("\n").map { |t| t.gsub(/\s/, '') }
tasks = tasks.select { |t| /^#{Regexp.escape task_match}/ =~ t } if task_match

# handle namespaces
if task_match =~ /^([-\w:]+:)/
  upto_last_colon = $1
  after_match = $'
  tasks = tasks.map { |t| (t =~ /^#{Regexp.escape upto_last_colon}([-\w:]+)$/) ? "#{$1}" : t }
end

puts tasks
exit 0