# frozen_string_literal: true

##
# id must be the id attribute of the editor instance (without the #) e.g.
#     <textarea id="foo" ...></textarea>
# would be filled in by calling
#     tinymce_fill_in 'foo', 'some stuff'
#
def tinymce_fill_in(id, val)
  # wait until the TinyMCE editor instance is ready. This is required for cases
  # where the editor is loaded via XHR.
  sleep 0.5 until page.evaluate_script("tinyMCE.get('#{id}') !== null")

  js = "tinyMCE.get('#{id}').setContent('#{val}')"
  page.execute_script(js)
end
