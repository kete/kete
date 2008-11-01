EXTENDED_VALID_ELEMENTS = 'code[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],form[accept|accept-charset|action|class|dir<ltr?rtl|enctype|id|lang|method<get?post|name|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onreset|onsubmit|style|title|target],input[accept|accesskey|align<bottom?left?middle?right?top|alt|checked<checked|class|dir<ltr?rtl|disabled<disabled|id|ismap<ismap|lang|maxlength|name|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onselect|readonly<readonly|size|src|style|tabindex|title|type<button?checkbox?file?hidden?image?password?radio?reset?submit?text|usemap|value],select[class|dir<ltr?rtl|disabled<disabled|id|lang|multiple<multiple|name|onblur|onchange|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|size|style|tabindex|title],"option[class|dir<ltr?rtl|disabled<disabled|id|label|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|selected<selected|style|title|value],label[accesskey|class|dir<ltr?rtl|for|id|lang|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],object[classid|codebase|width|height|align],param[name|value],embed[quality|type|pluginspage|width|height|src|align|wmode]'

VALID_TINYMCE_ACTIONS = ['new', 'create', 'edit', 'update', 'pick_topic_type', 'homepage_options', 'new_related_set_from_archive_file']

DEFAULT_TINYMCE_SETTINGS = {
  # advanced theme settings
  :theme => 'advanced',
  :theme_advanced_toolbar_location => "top",
  :theme_advanced_toolbar_align => "left",
  :theme_advanced_statusbar_location => "bottom",
  :theme_advanced_buttons1 => %w{ bold italic underline strikethrough separator justifyleft justifycenter justifyright justifyfull separator indent outdent separator bullist numlist forecolor backcolor separator link unlink image separator undo redo separator code},
  :theme_advanced_buttons2 => %w{ formatselect fontselect fontsizeselect separator pastetext pasteword selectall },
  :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen },
  :theme_advanced_resizing => true,
  :theme_advanced_resize_horizontal => false,

  # link / image path conversions
  :convert_urls => false,
  :content_css => "/stylesheets/base.css",

  # paste plugin specific settings
  :paste_auto_cleanup_on_paste => true,
  :paste_convert_middot_lists => false,
  :paste_convert_headers_to_strong => true,

  # which plugins we are enabling
  :plugins => %w{ contextmenu paste table fullscreen }
}