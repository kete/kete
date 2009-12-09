<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:z="http://indexdata.dk/zebra/xslt/1"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  exclude-result-prefixes="oai_dc dc z oai"
  version="1.0">

  <!-- switch to non-indented version after debugging -->
  <xsl:output indent="no" method="xml" version="1.0" encoding="UTF-8"/>
  <!-- <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/> -->

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on oai xml record -->
  <xsl:template match="/">
    <record xmlns="http://www.openarchives.org/OAI/2.0/">
      <xsl:apply-templates/>
    </record>
  </xsl:template>

  <!-- header -->
  <xsl:template match="oai:record/oai:header">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- ability to select n amount of words -->
  <!-- http://mdasblog.wordpress.com/2009/01/20/displaying-the-first-n-words-of-a-long-text-column-with-xsl/ -->
  <xsl:template name="FirstNWords">
    <xsl:param name="TextData"/>
    <xsl:param name="WordCount"/>
    <xsl:param name="MoreText"/>
    <xsl:choose>
      <xsl:when test="$WordCount > 1 and
                      (string-length(substring-before($TextData, ' ')) > 0 or
                      string-length(substring-before($TextData, '  ')) > 0)">
        <xsl:value-of select="concat(substring-before($TextData, ' '), ' ')"/>
        <xsl:call-template name="FirstNWords">
          <xsl:with-param name="TextData" select="substring-after($TextData, ' ')"/>
          <xsl:with-param name="WordCount" select="$WordCount - 1"/>
          <xsl:with-param name="MoreText" select="$MoreText"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="(string-length(substring-before($TextData, ' ')) > 0 or
                       string-length(substring-before($TextData, '  ')) > 0)">
        <xsl:value-of select="concat(substring-before($TextData, ' '), $MoreText)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$TextData"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- here's the meat, include only the dc elements we need -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc">
    <metadata xmlns="http://www.openarchives.org/OAI/2.0/">
      <oai_dc:dc xmlns:dcterms="http://purl.org/dc/terms/"
		 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		 xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
		 xmlns:dc="http://purl.org/dc/elements/1.1/"
		 xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
	<xsl:for-each select="dc:identifier">
	  <dc:identifier><xsl:value-of select="."/></dc:identifier>
	</xsl:for-each>
	<xsl:for-each select="dc:title">
	  <dc:title><xsl:value-of select="."/></dc:title>
	</xsl:for-each>
	<!-- dc:description, we only need the first one -->
	<xsl:for-each select="dc:description">
	  <xsl:if test="position()=1 and count(child::*)=0">
	    <dc:description>
	      <xsl:call-template  name="FirstNWords">
	        <xsl:with-param name="TextData" select="."/>
	        <xsl:with-param name="WordCount" select="100"/>
	        <xsl:with-param name="MoreText" select="'...'"/>
	      </xsl:call-template>
	    </dc:description>
	  </xsl:if>
	</xsl:for-each>
	<xsl:for-each select="dc:date">
	  <dc:date><xsl:value-of select="."/></dc:date>
	</xsl:for-each>
	<!-- dc:creator, we only need the first two -->
	<xsl:for-each select="dc:creator">
	  <xsl:if test="position()=1">
	    <dc:creator><xsl:value-of select="."/></dc:creator>
	  </xsl:if>
	  <xsl:if test="position()=2">
	    <dc:creator><xsl:value-of select="."/></dc:creator>
	  </xsl:if>
	</xsl:for-each>
	<!-- dc:contributor, we only need the last two -->
	<xsl:for-each select="dc:contributor">
	  <xsl:if test="position()=last()-1">
	    <dc:contributor><xsl:value-of select="."/></dc:contributor>
	  </xsl:if>
	  <xsl:if test="position()=last()">
	    <dc:contributor><xsl:value-of select="."/></dc:contributor>
	  </xsl:if>
	</xsl:for-each>
	<!-- we want dc:coverage for geographic, temporal, and topic type data -->
	<xsl:for-each select="dc:coverage">
	  <dc:coverage><xsl:value-of select="."/></dc:coverage>
	</xsl:for-each>
	<!-- we may want to display license in results eventually -->
	<xsl:for-each select="dc:rights">
	  <dc:rights><xsl:value-of select="."/></dc:rights>
	</xsl:for-each>
      </oai_dc:dc>
    </metadata>
  </xsl:template>

  <!-- dc:identifier -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:identifier">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- kete -->
  <xsl:template match="oai:record/oai:kete">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>
