<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:z="http://indexdata.dk/zebra/xslt/1"
                xmlns:oai="http://www.openarchives.org/OAI/2.0/"
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                version="1.0">

  <!-- xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" -->


  <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on oai xml record -->
  <xsl:template match="/">
    <z:record z:id="{normalize-space(oai:record/oai:header/oai:identifier)}"
              z:type="update">

      <xsl:apply-templates/>
    </z:record>
  </xsl:template>

  <!-- possible TODO: add sorting indexes -->
  <!-- i've added word or phrase indexing where relevant, may need tweaking -->

  <!-- OAI indexing templates -->
  <xsl:template match="oai:record/oai:header/oai:identifier">
    <z:index name="oai_identifier" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="oai_identifier" type="w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:header/oai:datestamp">
    <z:index name="oai_datestamp" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="oai_datestamp" type="d">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="date_modified" type="s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:header/oai:setSpec">
    <z:index name="oai_setspec" type="0">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- DC specific indexing templates -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:title">
    <z:index name="dc_title" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_title" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="sort_by_title" type="s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:creator">
    <z:index name="dc_creator" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_creator" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="sort_by_creator" type="s">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:subject">
    <z:index name="dc_subject" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_subject" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:description">
    <z:index name="dc_description" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:contributor">
    <z:index name="dc_contributor" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_contributor" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:publisher">
    <z:index name="dc_publisher" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_publisher" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <!--
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
    -->
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:date">
    <z:index name="dc_date" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_date" type="d">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:format">
    <z:index name="dc_format" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <!--
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    -->
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:identifier">
    <z:index name="dc_identifier" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_identifier" type="u">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="u">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:source">
    <z:index name="dc_source" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_source" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_source" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <!-- Walter McGinnis (walter@katipo.co.nz), 2006-12-01 -->
  <!-- added type -->
  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:type">
    <z:index name="dc_type" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <!--
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    -->
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:language">
    <z:index name="dc_language" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <!--
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    -->
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:relation">
    <z:index name="dc_relation" type="0">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_relation" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_relation" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:coverage">
    <z:index name="dc_rights" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_rights" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

  <xsl:template match="oai:record/oai:metadata/oai_dc:dc/dc:rights">
    <z:index name="dc_rights" type="p">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_rights" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="w">
      <xsl:value-of select="."/>
    </z:index>
    <z:index name="dc_all" type="p">
      <xsl:value-of select="."/>
    </z:index>
  </xsl:template>

</xsl:stylesheet>
