module RailsUpgradeHelper
  # Code added for the Rails 2 to Rails 3 upgrade
  # !! should be replace with better Rails 3 solutions.

  # Work with link_to, to replace page content
  # !! replace with proper UJS
  def update_elem_with_ajax_result(hash)
    j_ajax_elem = j(hash[:ajax_elem])
    j_update = j(hash[:update])

    rtn = <<~EOF
      <script>
         (function() {
          // Work link_to, to replace page content (!! replace with proper UJS)
          $('##{j_ajax_elem}').bind('ajax:complete', function(et, e){
            $('##{j_update}').html(e.responseText);
          });
        }).call();
      </script>
EOF

    rtn.html_safe
  end
end
