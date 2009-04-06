<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:z="http://indexdata.dk/zebra/xslt/1"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  version="1.0">

  <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on oai xml record -->
  <xsl:template match="/">
    <dc:metadata>
       <xsl:apply-templates/>
    </dc:metadata>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/node()">
      <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>
