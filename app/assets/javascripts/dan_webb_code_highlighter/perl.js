CodeHighlighter.addStyle("perl",{
  comment : {
    exp  : /#[^\n]*/
  },
  string : {
    exp  : /'[^']*'|"[^"]*"|`[^`]*`/
  },
  keywords : {
    exp  : /(use|package|sub|new|return|my|print|if|elsif|else|say|echo)/
  }
});