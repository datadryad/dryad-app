
Dash is an open source, community driven project that takes a unique approach to data publication and digital preservation. Dash focuses on search, presentation, and discovery and delegates the responsibility for the data preservation function to the underlying repository with which it is integrated.

Dash is based at the [University of California Curation Center](http://www.cdlib.org/uc3) (UC3), a program at [California Digital Library](http://www.cdlib.org) (CDL) that aims to develop interdisciplinary research data infrastructure. Dash employs a multi-tenancy user interface providing partners with extensive opportunities for local branding and customization, use of existing campus login credentials, and, importantly, offering the Dash service under a tenant-specific URL, an important consideration helping to drive adoption. We welcome collaborations with other organizations wishing to provide a simple, intuitive data publication service on top of more cumbersome legacy systems.

There are currently ten live instances of Dash:
- [UC Berkeley](https://dash.berkeley.edu/)
- [UC Irvine](https://dash.lib.uci.edu/)
- [UC Merced](https://dash.ucmerced.edu/)
- [UC Office of the President](https://dash.ucop.edu/)
- [UC Riverside](https://dash.ucr.edu/)
- [UC Santa Cruz](https://dash.library.ucsc.edu/)
- [UC San Francisco](https://datashare.ucsf.edu/)
- [UC Davis](https://dash.ucdavis.edu/)
- [UC Press](https://dash.ucpress.edu/)
- [ONEshare](https://oneshare.cdlib.org/) (in partnership with [DataONE](http://dataone.org/))

For information about Submission to Dash check out our [guidance here](https://github.com/CDLUC3/dashv2/blob/master/app/views/layouts/_help.html.md)


## Architecture and Implementation

Dash is completely open source.  Our code is made publicly available on GitHub (http://cdluc3.github.io/dash/).  Dash is based on an underlying Ruby-on-Rails data publication platform called Stash. Stash encompasses three main functional components: Store, Harvest, and Share.

- Store: The Store component is responsible for the selection of datasets; their description in terms of configurable metadata schemas, including specification of ORCID and Fundref identifiers for researcher and funder disambiguation; the assignment of DOIs for stable citation and retrieval; designation of an optional limited time embargo; and packaging and submission to the integrated repository
- Harvest: The Harvest component is responsible for retrieval of descriptive metadata from that repository for inclusion into a Solr search index
- Share: The Share component, based on GeoBlacklight, is responsible for the faceted search and browse interface

<a href="/dash_architecture_diagram.png"><img src="/dash_architecture_diagram.png" alt="Dash Architecture Diagram" style="width: 500px;"/></a>

Individual dataset landing pages are formatted as an online version of a data paper, presenting all appropriate descriptive and administrative metadata in a form that can be downloaded as an individual PDF file, or as part of the complete dataset download package, incorporating all data files for all versions.

To facilitate flexible configuration and future enhancement, all support for the various external service providers and
repository protocols are fully encapsulated into pluggable modules. Metadata modules are available for the DataCite and
Dublin Core metadata schemas. Protocol modules are available for the SWORD 2.0 deposit protocol and the OAI-PMH and
ResourceSync harvesting protocols. Authentication modules are available for InCommon/Shibboleth18 and Google/OAuth
identity providers (IdPs).

We welcome collaborations to develop additional modules for additional metadata schemas and repository protocols.  Please email UC3 (uc3 at ucop dot edu) or visit GitHub (http://cdluc3.github.io/dash/) for more information.


## Features of Dash service

| Feature | Tech-focused | User-focused | Description |
|:---------------------------------|:-------------------------:|:------------------:|:--------------|
| Open Source | X |  | All components open source, MIT licensed code (http://cdluc3.github.io/dash/) |
| Standards compliant | X |  | Dash integrates with any SWORD/OAI-PMH-compliant repository |
| Pluggable Framework | X |  | Inherent extensibility for supporting additional protocols and metadata schemas |
| Flexible metadata schemas | X |  | Support Datacite metadata schema out-of-the-box, but can be configured to support any schema |
| Innovation | X |  | Our modular framework will make new feature development easier and quicker |
| Mobile/responsive design | X | X | Built mobile-first, from the ground up, for better user experience |
| Geolocation - Metadata | X | X | For applicable research outputs, we have an easy to use way to capture location of your datasets |
| Persistent Identifers - ORCID | X | X | Dash allows researchers to attach their ORCID, allowing them to track and get credit for their work |
| Persistent Identifers - DOIs | X | X | Dash issues DOIs for all datasets, allowing researchers to track and get credit for their work |
| Persistent Identifers - Fundref | X | X | Dash tracks funder information using FundRef, allowing researchers and funders to track their reasearch outputs |
| Login - Shibboleth /OAuth2 | X | X | We offer easy single-sign with your campus credentials or Google account |
| Versioning | X | X | Datasets can change. Dash offers a quick way for you to upload new versions of your datasets and offer a simple process for tracking updates |
| Accessibility | X | X | The technology, design, and user workflows have all been built with accessibility in mind |
| Better user experience |  | X | Self-depositing made easy. Simple workflow, drag-and-drop upload, simple navigation, clean data publication pages, user dashboards |
| Geolocation - Search |  | X | With GeoBlacklight, we can offer search by location |
| Robust Search |  | X | Search by subject, filetype, keywords, campus, location, etc. |
| Discoverability |  | X | Indexing by search engines for Google, Bing, etc. |
| Build Relationships |  | X | Many datasets are related to publications or other data. Dash offers a quick way to describe these relationships |
| Supports Best Practices |  | X | Data publication can be confusing. But with Dash, you can trust Dash is following best practices |
| Data Metrics |  | X | See the reach of your datasets through usage and download metrics |
| Data Citations |  | X | Quick access to a well-formed citiation reference (with DOI) to every data publication. Easy for your peers to quickly grab |
| Open License |  | X | Dash supports open Creative Commons licensing for all data deposits; can be configured for other licenses |
| Lower Barrier to Entry |  | X | For those in a hurry, Dash offers a quick interface to self-deposit. Only three steps and few required fields |
| Support Data Reuse |  | X | Focus researchers on describing methods and explaining ways to reuse their datasets |
| Satisfies Data Availability Requirements |  | X | Many publishers and funders require researchers to make their data available. Dash is an readily accepted and easy way to comply |


## Dash History

The Dash project began as [DataShare](http://datashare.ucsf.edu/), a collaboration among [UC3](http://www.cdlib.org/uc3), the [University of California San Francisco Library and Center for Knowledge Management](http://www.library.ucsf.edu/),
and the [UCSF Clinical and Translational Science Institute](http://ctsi.ucsf.edu/) (CTSI). CTSI is part of the Clinical and Translational Science Award program funded by the National Center for Advancing Translational Sciences at the National Institutes of Health. Dash version 2 developed by UC3 and partners with funding from the Alfred P. Sloan Foundation ([our funded proposal](http://escholarship.org/uc/item/2mw6v93b)).  Read more about the code, the project, and contributing to development on the [Dash GitHub site](http://cdluc3.github.io/dash)




