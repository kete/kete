CodeHighlighter.addStyle("xml", {
	comment : {
		exp: /&lt;!\s*(--([^-]|[\r\n]|-[^-])*--\s*)&gt;/
	},
	tag : {
		exp: /(&lt;\/?)([a-zA-Z]+\s?)/, 
		replacement: "$1<span class=\"$0\">$2</span>"
	},
	attribute : {
		exp: /\b([a-zA-Z-:]+)(=)/, 
		replacement: "<span class=\"$0\">$1</span>$2"
	},
	doctype : {
		exp: /&lt;\?xml.*&gt;/
	}
});