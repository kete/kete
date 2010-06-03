fields = Hash.new
fields[:code]  = '[class|dir<ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title]'
fields[:form]  = '[accept|accept-charset|action|class|dir<ltr?rtl|enctype|id|lang|method<get?post|name|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onreset|onsubmit|style|title|target]'
fields[:input] = '[accept|accesskey|align<bottom?left?middle?right?top|alt|checked<checked|class|dir<ltr?rtl|disabled<disabled|id|ismap<ismap|lang|maxlength|name|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onselect|readonly<readonly|size|src|style|tabindex|title|type<button?checkbox?file?hidden?image?password?radio?reset?submit?text|usemap|value]'
fields[:select] = '[class|dir<ltr?rtl|disabled<disabled|id|lang|multiple<multiple|name|onblur|onchange|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|size|style|tabindex|title]'
fields[:option] = '[class|dir<ltr?rtl|disabled<disabled|id|label|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|selected<selected|style|title|value]'
fields[:label] = '[accesskey|class|dir<ltr?rtl|for|id|lang|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title]'
fields[:object] = '[classid|codebase|width|height|align|data|type]'
fields[:param] = '[name|value]'
fields[:embed] = '[quality|type|pluginspage|width|height|src|align|wmode|flashvars|allowfullscreen]'
EXTENDED_VALID_ELEMENTS_HASH = fields
EXTENDED_VALID_ELEMENTS = fields.collect { |k,v| "#{k}#{v}" }.join(',')
INSECURE_EXTENDED_VALID_ELEMENTS = [:form, :input, :select, :option, :script]

VALID_TINYMCE_ACTIONS = ['new', 'create', 'edit', 'update', 'homepage_options', 'appearance', 'choose_type', 'render_item_form', 'new_related_set_from_archive_file', 'restore']
