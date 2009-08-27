<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:z="http://indexdata.dk/zebra/xslt/1"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  version="1.0">

  <!-- switch to non-indented version after debugging -->
  <!-- <xsl:output indent="no" method="xml" version="1.0" encoding="UTF-8"/> -->
  <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on oai xml record -->
  <xsl:template match="/">
    <record>
      <xsl:apply-templates/>
    </record>
  </xsl:template>

  <!-- header -->
  <xsl:template match="oai:record/oai:header">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- here's the meat, include only the dc elements we need -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc">
    <metadata>
      <oai_dc:dc>
	<xsl:for-each select="dc:identifier">
	  <dc:identifier><xsl:value-of select="."/></dc:identifier>
	</xsl:for-each>
	<xsl:for-each select="dc:title">
	  <dc:title><xsl:value-of select="."/></dc:title>
	</xsl:for-each>
	<!-- dc:description, we only need the first one -->
	<xsl:for-each select="dc:description">
	  <xsl:if test="position()=1">
	    <dc:description><xsl:value-of select="."/></dc:description>
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
