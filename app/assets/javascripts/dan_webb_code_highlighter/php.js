CodeHighlighter.addStyle("php",{
  comment : {
    exp  : /(\/\/[^\n]*(\n|$))|(\/\*[^*]*\*+([^\/][^*]*\*+)*\/)/
  },
  string : {
    exp  : /'[^']*'|"[^"]*"|`[^`]*`/
  },
  keywords : {
    exp  : /(define|include|require|include_once|require_once|for|do|while|header|return|class|function|if)/
  },
  global : {
    exp  : /(echo|print)/
  }
});