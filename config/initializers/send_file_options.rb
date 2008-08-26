=begin

= Private file send_file method =

Kete can store and retrieve private files, which are kept in a separate folder called 'private'
under the application root directly (i.e. /home/user/apps/your_app/private).

When using Nginx and Mongrel or Apache and mod_rails/Passenger to serve a Kete instance, significant 
performance improvements can be made by using special proxy-specific headers to send privately
stored files to the browser.

These headers are X-Accel-Redirect for Nginx, and X-SENDFILE for Apache.

In order to support these headers, the following steps must be made:

1.  Prepare your proxy server to use the appropriate send_file header.
    (See specific instructions below.)
    
    1.1   Nginx
    
          a)  Open your Nginx configuration file or vhost file (normally nginx.conf) and add the 
              following declaration to your 'server' configuration blocks.
              
              location /private/ {
                root /home/user/apps/kete/;   # Be sure to replace this with the actual location of
                                              # your Kete instance. The trailing slash is imporant.
                internal;
              }
              
          b)  Restart your Nginx server. If it fails to restart, check your error logs/console for 
              any syntax errors in the configuration files.
              
          NB: Without the declaration above, the X-Accel-Redirect header will not function correctly.
          
    1.2   Apache
    
          a)  See http://tn123.ath.cx/mod_xsendfile/ for mod_xsendfile installation and configuration.
          
          NB: mod_xsendfile and Apache2's X-SendFile header are not current tested with this setting,
              proceed with caution. Report any issues to 
              http://kete.lighthouseapp.com/projects/14288-kete.
              
2.  Change the Ruby constant below to one of the following settings:

    * "" (empty string):  use Ruby on Rails's native send_file method, streaming the file directly 
                          from your web server (e.g. Mongrel cluster, etc). This works out-of-the-box.
                          
    * "nginx":            send Nginx's X-Accel-Redirect header instead of streaming the file, causing
                          Nginx to send the file directly without using a mongrel instance to stream 
                          files. This requires Nginx to be configured correctly as per step 1.1 above
                          to work successfully.
                          
    * "apache":           send Apache2 + mod_xsendfile's X-SENDFILE header instead of streaming the file,
                          causing Apache2 to stream the file directly. This requires Apache2 and 
                          mod_xsendfile to be installed and configured correctly. This is currently 
                          untested.

3.  Restart your Kete instance. This will require either stopping and starting Mongrel clusters, or
    restarting your Apache2 instance depending on your server environment.
                          
4.  Test your Kete instance by uploading and downloading a private file. The log should display what 
    method is being used to send the file to the browser. (Streaming file.. is the default.)

Notes:

* As the Apache2 + mod_xsendfile method is untested, any feedback or further instructions are appreciated.
  Please report any issues to http://kete.lighthouseapp.com/projects/14288-kete.
  
* The safest option (and also the slowest) is to use Ruby on Rails's native send_file method. Set the ruby 
  constant below to an empty string (i.e. SENDFILE_METHOD = "") to use this.
  
=end

# Select which send_file method to use to send private files to a browser from a Kete instance.
# Valid values are "", "nginx", or "apache".

SENDFILE_METHOD = ""



# (Do not edit below here.)

unless ["", "apache", "nginx"].member?(SENDFILE_METHOD)
  print "/!\\ WARNING: Incorrect value for SENDFILE_METHOD in config/initializers/send_file_options.rb on line 77. Should be one of \"\", \"apache\", or \"nginx\"; but was \"#{SENDFILE_METHOD}\". /!\\\n"
end