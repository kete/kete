/*
 *= require jquery
 *= require jquery_ujs
 *= require tinymce-jquery
 */

/**
 * Initialize TinyMCE on all pages
 * This is a replacement for invoking
 *    = tinymce
 * in a Haml template. We are doing it manually (instead of using the helper
 * provide by the tinymce gem) because we need to re-initialize tinyMCE on
 * pages where we load content via XHR (e.g "Add item" form) anyway and it is
 * more consistent to have one method.
 *
 */

var setupTinyMCE = function() {
  var options = {
    selector: 'textarea.tinymce',
    menubar: false,
    toolbar: ['bold, italic, underline, strikethrough, separator, justifyleft, justifycenter, justifyright, justifyfull, separator, subscript, superscript, separator, indent, outdent, separator', 'bullist, numlist, forecolor, backcolor, separator, link, unlink, separator, undo, redo, removeformat, separator, code, formatselect, fontselect, fontsizeselect, separator', 'image, table, cut, copy, paste, fullscreen, selectall, media'],
    tools: 'inserttable',
    plugins: 'contextmenu, image, paste, table, fullscreen, textcolor, link',
  };

  if (typeof tinyMCE === 'object') {
    tinyMCE.init(options);
  }
};

$(document).ready(function() {
  setupTinyMCE();
});
