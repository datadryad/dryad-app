# What we do

Dryad advances our vision – for the open availability and routine reuse of research data to drive the acceleration of discovery and translation of research into benefits for society – by enabling the open publication and routine reuse of all research data. 

**We make it easier to share, find, use and cite data, and are ready-made for emerging data-sharing requirements.**

* Data curation at Dryad – Ensures data is appropriate and licensed for sharing; Verifies data is accessible and usable; and Supports authors.
* Data publishing at Dryad – Ensures metadata quality; Increases discoverability of data; Connects data with other research outputs; Promotes data citation; and Makes data count.
* The Dryad platform – Offers a smooth and easy publishing experience for authors; Integrates readily with publisher workflows; Runs on open-source software; May be accessed via open API.

Dryad serves all research domains and welcomes submissions of data in every field – where there is not an existing specialist repository and where the data may be shared openly. Dryad publishes data exclusively under a [Creative Commons Public Domain License](https://creativecommons.org/share-your-work/public-domain/cc0/) (CC0) and does not support the publication of sensitive data, to which access should be restricted.

Our custom process is dedicated exclusively to research data. We work in concert with [aligned organizations](/stash/about#collaborations) to facilitate the release and interconnection of related software, supplementary information, research articles, preprints, data management plans and more. 

See [how Dryad compares with other platforms](https://doi.org/10.5281/zenodo.7189481). 

## Latest news

<div id="blog-latest-posts" data-count="3">
  <%= image_tag 'stash_engine/spinner.gif', size: '80x60', alt: 'Loading spinner' %>
</div>
<p style="text-align:right"><a href="https://blog.datadryad.org">More news from Dryad →</a></p>

## Our curation and publication process

Since 2007 Dryad has been a leader in curating and openly publishing research data across domains. For the community of academic and research institutions, research funders, scholarly societies, publishers and individual researchers that invest in Dryad, our service offers expertise, capacity, accountability and quality.

At Dryad, curation is the process of thoroughly evaluating research metadata and related objects to verify that data are accessible, organized, intelligible, and complete to ensure ease of re-use. Curators collaborate with researchers to confirm that data are appropriate for open sharing, follow FAIR principles, and meet ethical standards for publication. They also offer guidance on best practices for creating reusable data and help authors navigate publication requirements. 

Dryad Curators do not verify, validate or authenticate data for scientific reuse, however, they do assess submissions carefully and raise questions for investigation/escalation when there are concerns about the reusability, provenance, interoperability, or comprehensibility of the data submitted for publication in Dryad. We do not attempt to assess rigor. 

Data publishing is the presentation of openly available and citable research data that is optimized to promote discoverability, connected to enhance visibility, and protected to guarantee the long-term preservation of quality research data. 

Together, these processes ensure equitable access to data, and create opportunities to foster new collaborations and connections across the research community—helping Dryad to achieve our vision for the acceleration of discovery and translation of research into benefits for society.

For a demonstration of our process, please [contact us](/stash/interested). 

Learn more:

* [Submission and publication process](/stash/submission_process)
* [Data publishing ethics](/stash/ethics)
* [Good data practices](/stash/best_practices)

## Our platform

### Architecture and implementation

Dryad is completely open source.  Our code is made publicly available [on GitHub](https://github.com/CDL-Dryad/dryad-app). Dryad is based on an underlying Ruby-on-Rails data publication platform called Stash. Stash encompasses three main functional components: Store, Harvest, and Share.

- Store: The Store component is responsible for the selection of datasets; their description in terms of configurable metadata schemas, including specification of ORCID and Fundref identifiers for researcher and funder disambiguation; the assignment of DOIs for stable citation and retrieval; designation of an optional limited time embargo; and packaging and submission to the integrated repository
- Harvest: The Harvest component is responsible for retrieval of descriptive metadata from that repository for inclusion into a Solr search index
- Share: The Share component, based on GeoBlacklight, is responsible for the faceted search and browse interface

<p><a href="/images/dash_architecture_diagram.png" target="_blank" style="display: block;"><img src="/images/dash_architecture_diagram.png" alt="Dash Architecture Diagram"></a></p>

Individual dataset landing pages are formatted as an online version of a data paper, presenting all appropriate descriptive and administrative metadata in a form that can be downloaded as an individual PDF file, or as part of the complete dataset download package, incorporating all data files for all versions.

To facilitate flexible configuration and future enhancement, all support for the various external service providers and repository protocols are fully encapsulated into pluggable modules. Metadata modules are available for the DataCitemetadata schema. Protocol modules are available for the SWORD 2.0 deposit protocol. Authentication modules are available for InCommon/Shibboleth18 and ORCID identity providers (IdPs).

We welcome collaborations to develop additional modules for additional metadata schemas and repository protocols. Please email the Dryad [help desk](mailto:help@datadryad.org) or [visit GitHub](https://github.com/CDL-Dryad/dryad-app) for more information.

### Features of Dryad service

<div style="max-width: 100%; overflow-x: auto; overflow-y: hidden">
<table style=""><thead>
<tr>
<th style="text-align: left">Feature</th>
<th style="text-align: center">Tech-focused</th>
<th style="text-align: center">User-focused</th>
<th style="text-align: left">Description</th>
</tr>
</thead><tbody>
<tr>
<td style="text-align: left">Open Source</td>
<td style="text-align: center">X</td>
<td style="text-align: center"></td>
<td style="text-align: left">All components open source, <a href="https://github.com/CDL-Dryad/dryad-app">MIT licensed code</a></td>
</tr>
<tr>
<td style="text-align: left">Standards compliant</td>
<td style="text-align: center">X</td>
<td style="text-align: center"></td>
<td style="text-align: left">Dryad integrates with any SWORD-compliant repository</td>
</tr>
<tr>
<td style="text-align: left">Pluggable Framework</td>
<td style="text-align: center">X</td>
<td style="text-align: center"></td>
<td style="text-align: left">Inherent extensibility for supporting additional protocols and metadata schemas</td>
</tr>
<tr>
<td style="text-align: left">Flexible metadata schemas</td>
<td style="text-align: center">X</td>
<td style="text-align: center"></td>
<td style="text-align: left">Support Datacite metadata schema out-of-the-box, but can be configured to support any schema</td>
</tr>
<tr>
<td style="text-align: left">Innovation</td>
<td style="text-align: center">X</td>
<td style="text-align: center"></td>
<td style="text-align: left">Our modular framework will make new feature development easier and quicker</td>
</tr>
<tr>
<td style="text-align: left">Mobile/responsive design</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">Built mobile-first, from the ground up, for better user experience</td>
</tr>
<tr>
<td style="text-align: left">Geolocation - Metadata</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">For applicable research outputs, we have an easy to use way to capture location of your datasets</td>
</tr>
<tr>
<td style="text-align: left">Persistent Identifers - ORCID</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">Dryad requires ORCID for login and allows for co-authors to attach their ORCID, allowing them to track their work</td>
</tr>
<tr>
<td style="text-align: left">Persistent Identifers - DOIs</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">Dryad issues DOIs for all datasets, allowing researchers to track and get credit for their work</td>
</tr>
<tr>
<td style="text-align: left">Persistent Identifers - Funder Registry</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">Dryad tracks funder information using Crossref's Funder Registry, allowing researchers and funders to track their reasearch outputs</td>
</tr>
<tr>
<td style="text-align: left">Persistent Identifers - Research Organization Registry</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">Dryad tracks institutional affiliations with ROR IDs, allowing institutions to track their reasearch outputs</td>
</tr>
<tr>
<td style="text-align: left">Login - Shibboleth /OAuth2</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">We offer easy single-sign with your campus credentials and ORCID account</td>
</tr>
<tr>
<td style="text-align: left">Versioning</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">Datasets can change. Dryad offers a quick way for you to upload new versions of your datasets and offer a simple process for tracking updates</td>
</tr>
<tr>
<td style="text-align: left">Accessibility</td>
<td style="text-align: center">X</td>
<td style="text-align: center">X</td>
<td style="text-align: left">The technology, design, and user workflows have all been built with accessibility in mind</td>
</tr>
<tr>
<td style="text-align: left">Better user experience</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Self-depositing made easy. Simple workflow, drag-and-drop upload, simple navigation, clean data publication pages, user dashboards</td>
</tr>
<tr>
<td style="text-align: left">Geolocation - Search</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">With GeoBlacklight, we can offer search by location</td>
</tr>
<tr>
<td style="text-align: left">Robust Search</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Search by subject, filetype, keywords, campus, location, etc.</td>
</tr>
<tr>
<td style="text-align: left">Discoverability</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Indexing by search engines including Google Dataset Search</td>
</tr>
<tr>
<td style="text-align: left">Build Relationships</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Many datasets are related to publications or other data. Dryad offers a quick way to describe these relationships</td>
</tr>
<tr>
<td style="text-align: left">Supports Best Practices</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Data publication can be confusing. But with Dryad, you can trust deposits are following best practices</td>
</tr>
<tr>
<td style="text-align: left">Data Metrics</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">See the reach of your datasets through standardized (Make Data Count) usage and download metrics</td>
</tr>
<tr>
<td style="text-align: left">Data Citations</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Quick access to a well-formed citiation reference (with DOI) to every data publication. Easy for your peers to quickly grab</td>
</tr>
<tr>
<td style="text-align: left">Open License</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Dryad supports open Creative Commons licensing for all data deposits</td>
</tr>
<tr>
<td style="text-align: left">Support Data Reuse</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Focus researchers on describing methods and explaining ways to reuse their datasets</td>
</tr>
<tr>
<td style="text-align: left">Satisfies Data Availability Requirements</td>
<td style="text-align: center"></td>
<td style="text-align: center">X</td>
<td style="text-align: left">Many publishers and funders require researchers to make their data available. Dryad is an readily accepted and easy way to comply</td>
</tr>
</tbody></table>
</div>

### History

Dryad's original iteration launched in 2009 and was built upon the open-source DSpace repository software. In 2019, Dryad merged with Dash, a data publication service developed at the [University of California Curation Center](http://www.cdlib.org/uc3) (UC3), a program at [California Digital Library](http://www.cdlib.org) (CDL). See more about [the origins of Dryad](/stash/about#origins).
