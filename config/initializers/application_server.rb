#
# Kete Application Server
#
# In the case that Kete is being run on Passenger, we can activate a site restart button
# on the configuration interface when a tech admin edits system settings
#
# We can't do the same for mongrel because of how it starts/stops
#
# Valid choices:
#   passenger
#   mongrel

APPLICATION_SERVER = 'passenger'

# (Do not edit below here.)

unless ['passenger', 'mongrel'].member?(APPLICATION_SERVER)
  print "/!\\ WARNING: Incorrect value for APPLICATION_SERVER in config/initializers/APPLICATION_SERVER.rb on line 13. Should be one of \"passenger\", or \"mongrel\"; but was \"#{APPLICATION_SERVER}\". /!\\\n"
end
