puts
puts " ActsAsLicensed has been successfully installed."
puts " To complete configuration, generate the License table schema using "
puts " the following commands:"
puts "  ./script/generate acts_as_licensed_migration"
puts "  rake db:migrate"
puts
puts " You can also import a set of Creative Commons New Zealand licenses "
puts " (excluding No Derivate Works variants) using the following command:"
puts "  rake acts_as_licensed:import_nz_cc_licenses"
puts