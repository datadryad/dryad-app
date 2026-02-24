<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <xsl:param name="url"/>
  <xsl:param name="page" select="1"/>
  <xsl:param name="size" select="10"/>
  <xsl:param name="title" select="'Dryad search results'"/>
  <xsl:param name="desc"/>
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="response">
    <feed xml:lang="en">
      <title><xsl:value-of select="$title"/></title>
      <xsl:if test="$desc != ''">
        <subtitle><xsl:value-of select="$desc"/></subtitle>
      </xsl:if>
      <id><xsl:value-of select="$url"/></id>
      <updated>
        <xsl:apply-templates select="//doc[1]/date[@name='dct_issued_dt']"/>
      </updated>
      <author>
        <name>Dryad Digital Repository</name>
        <uri>https://datadryad.org</uri>
      </author>
      <xsl:apply-templates select="result"/>
    </channel>
  </xsl:template>

  <xsl:template match="result">
    <xsl:variable name="c" select="@numFound"/>
    <xsl:variable name="pages" select="round($c div $size)"/>
    <xsl:variable name="join">
      <xsl:choose>
        <xsl:when test="contains($url, '?')">
          <xsl:text>&amp;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>?</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <link type="text/html" rel="alternate">
      <xsl:attribute name="href">
        <xsl:value-of select="concat(substring-before($url, '/search'), '/search', substring-after($url, 'search.xml'))"/>
      </xsl:attribute>
    </link>
    <link type="application/atom+xml" rel="self">
      <xsl:attribute name="href">
        <xsl:value-of select="concat($url, $join, 'page=', $page)"/>
      </xsl:attribute>
    </link>
    <link type="application/atom+xml" rel="first">
      <xsl:attribute name="href">
        <xsl:value-of select="$url"/>
      </xsl:attribute>
    </link>
    <link type="application/atom+xml" rel="last">
      <xsl:attribute name="href">
        <xsl:value-of select="concat($url, $join, 'page=', $pages)"/>
      </xsl:attribute>
    </link>
    <xsl:if test="$page &lt; $pages">
      <link type="application/atom+xml" rel="next">
        <xsl:attribute name="href">
          <xsl:value-of select="concat($url, $join, 'page=', $page + 1)"/>
        </xsl:attribute>
      </link>
    </xsl:if>
    <xsl:if test="$page > 1">
      <link type="application/atom+xml" rel="previous">
        <xsl:attribute name="href">
          <xsl:value-of select="concat($url, $join, 'page=', $page - 1)"/>
        </xsl:attribute>
      </link>
    </xsl:if>
    <xsl:apply-templates name="doc"/>
  </xsl:template>

  <xsl:template match="doc">
    <xsl:variable name="dataset" select="concat(substring-before($url, '/search'), '/dataset/', str[@name='dc_identifier_s']/text())"/>
    <entry>
      <updated>
        <xsl:apply-templates select="date[@name='dct_issued_dt']"/>
      </updated>
      <title>
        <xsl:apply-templates select="str[@name='dc_title_s']"/>
      </title>
      <summary type="text">
        <xsl:apply-templates select="str[@name='dc_description_s']"/>
      </summary>
      <link rel="alternate" type="text/html">
        <xsl:attribute name="href">
          <xsl:value-of select="$dataset"/>
        </xsl:attribute>
      </link>
      <id>
        <xsl:value-of select="$dataset"/>
      </id>
    </entry>
  </xsl:template>

  <xsl:template match="date | str">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="node() | processing-instruction() | comment()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@* | text() | comment() | processing-instruction()">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>