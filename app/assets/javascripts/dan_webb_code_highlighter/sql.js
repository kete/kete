CodeHighlighter.addStyle("sql",{
  comment : {
    exp  : /(--[^\n]*(\n|$))|(\/\*[^*]*\*+([^\/][^*]*\*+)*\/)/
  },
  string : {
    exp  : /'[^']*'|"[^"]*"|`[^`]*`/
  },
  keywords : {
    exp  : /\b(ADD|ALL|ALTER|ANALYZE|AND|AS|ASC|ASENSITIVE|BEFORE|DROP|TABLE|IF|EXISTS|CREATE|NOT|NULL|PRIMARY|KEY|CONSTRAINT|ENGINE|DEFAULT|default|FOREIGN|CHARSET|REFERENCES|LOCK|TABLES|UNLOCK|WRITE|INSERT|INTO|VALUES)\b/
  }
});