CodeHighlighter.addStyle("bash",{
  string : {
    exp  : /'[^']*'|"[^"]*"|`[^`]*`/
  },
  keywords : {
    exp  : /(grep|scp|ssh|cat|rake|clear|ls|ps|exit|mkdir|tar|cd|chmod|chown|print|echo|sudo|apt-get|git|svn\s|git-svn|gem|rails|ruby|mysql|mysqladmin|aptitude|wget)(\s|$)/
  },
  pipe : {
    exp : /\|/
  },
  amp : {
    exp : /\&/
  },
  dollar : {
    exp  : /\$\s|#\s/
  }
});