CodeHighlighter.addStyle("yml", {
  comment : {
    exp  : /#[^\n]*/
  },
  setting : {
    exp  : /(\w+:)(\s)?(\w+)?/,
    replacement: "<span class=\"key\">$1</span>$2<span class=\"value\">$3</span>"
  }
});