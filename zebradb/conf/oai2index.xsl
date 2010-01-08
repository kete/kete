<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:z="http://indexdata.com/zebra-2.0"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:oai="http://www.openarchives.org/OAI/2.0/"
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
                exclude-result-prefixes="oai oai_dc dc"
                version="1.0">

  <!-- xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" -->


  <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on oai xml record -->
  <xsl:template match="/">
    <z:record z:id="{normalize-space(oai:record/oai:header/oai:identifier)}">

      <xsl:apply-templates/>
    </z:record>
  </xsl:template>

  <!-- OAI indexing templates -->
  <!-- Walter McGinnis, 2009-04-04 (and way earlier)
       Adding sorting and other indexes -->
  <xsl:template match="oai:record/oai:header/oai:identifier">
    <z:index name="oai_identifier:0 oai_identifier:w oai_identifier:s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:header/oai:datestamp">
    <z:index name="oai_datestamp:0 oai_datestamp:d oai_datestamp:w oai_datestamp:s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:header/oai:setSpec">
    <z:index name="oai_setspec:0 oai_setspec:w oai_setspec:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- DC specific indexing templates -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:title
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:title">
    <z:index name="any:w any:p dc_title:w dc_title:p dc_title:s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:creator
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:creator">
    <z:index name="any:w any:p dc_creator:w dc_creator:p dc_creator:s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- added u index for urls, since we store web_links in dc:subject -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:subject
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:subject">
    <z:index name="any:w dc_subject:w dc_subject:p dc_subject:u">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:description
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:description">
    <z:index name="any:w dc_description:w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:contributor
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:contributor">
    <z:index name="any:w any:p dc_contributor:w dc_contributor:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:publisher
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:publisher">
    <z:index name="dc_publisher:p dc_publisher:w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:date
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:date">
    <z:index name="any:w dc_date:0 dc_date:d dc_date:w dc_date:s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:format
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:format">
    <z:index name="dc_format:0">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>
    <!-- <z:index name="any:w dc_format:0 dc_format:w"> -->

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:identifier
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:identifier">
    <z:index name="any:u any:w any:p dc_identifier:0 dc_identifier:u dc_identifier:w dc_identifier:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:source
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:source">
    <z:index name="any:w any:p dc_source:0 dc_source:u dc_source:w dc_source:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:language
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:language">
    <z:index name="dc_language:w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- Walter McGinnis (walter@katipo.co.nz), 2006-12-01 -->
  <!-- added type -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:type
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:type">
    <z:index name="dc_type:w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- Walter McGinnis (walter@katipo.co.nz) -->
  <!-- this is what we use to look up related items -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:relation
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:relation">
    <z:index name="any:u any:w any:p dc_relation:0 dc_relation:u dc_relation:w dc_relation:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- Walter McGinnis (walter@katipo.co.nz), 2008-08-30 -->
  <!-- added coverage to support things like topic type -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:coverage
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:coverage">
    <z:index name="any:w any:p dc_coverage:0 dc_coverage:w dc_coverage:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:rights
                    | oai:record/oai:metadata/oai_dc:dc/oai_dc:rights">
    <z:index name="any:w any:p dc_rights:0 dc_rights:w dc_rights:p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- Walter McGinnis (walter@katipo.co.nz), 2009-04-08 -->
  <!-- added special index for locations -->
  <!-- <xsl:template match="oai:record/oai:kete/location">
    <z:index name="kete_location:w ">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template> -->

</xsl:stylesheet>
