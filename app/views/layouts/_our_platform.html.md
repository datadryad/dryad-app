# Our platform

Dryad is an open source, community driven project that takes a unique approach to data publication and digital preservation. Dryad focuses on search, presentation, and discovery and delegates the responsibility for the data preservation function to the underlying repository with which it is integrated.

For information about submission to Dryad, see our [guidance here](<%= stash_url_helpers.submission_process_path %>).


## Architecture and implementation

Dryad is completely open source.  Our code is made publicly available [on GitHub](https://github.com/CDL-Dryad/dryad-app). Dryad is based on an underlying Ruby-on-Rails data publication platform called Stash. Stash encompasses three main functional components: Store, Harvest, and Share.

- Store: The Store component is responsible for the selection of datasets; their description in terms of configurable metadata schemas, including specification of ORCID and Fundref identifiers for researcher and funder disambiguation; the assignment of DOIs for stable citation and retrieval; designation of an optional limited time embargo; and packaging and submission to the integrated repository
- Harvest: The Harvest component is responsible for retrieval of descriptive metadata from that repository for inclusion into a Solr search index
- Share: The Share component, based on GeoBlacklight, is responsible for the faceted search and browse interface

<a href="/images/dash_architecture_diagram.png"><img src="/images/dash_architecture_diagram.png" alt="Dash Architecture Diagram" style="width: 500px;"/></a>

Individual dataset landing pages are formatted as an online version of a data paper, presenting all appropriate descriptive and administrative metadata in a form that can be downloaded as an individual PDF file, or as part of the complete dataset download package, incorporating all data files for all versions.

To facilitate flexible configuration and future enhancement, all support for the various external service providers and repository protocols are fully encapsulated into pluggable modules. Metadata modules are available for the DataCitemetadata schema. Protocol modules are available for the SWORD 2.0 deposit protocol. Authentication modules are available for InCommon/Shibboleth18 and ORCID identity providers (IdPs).

We welcome collaborations to develop additional modules for additional metadata schemas and repository protocols. Please email the Dryad [help desk](mailto:help@datadryad.org) or [visit GitHub](https://github.com/CDL-Dryad/dryad-app) for more information.

## Features of Dryad service

| Feature | Tech-focused | User-focused | Description                                                                                                                                   |
|:---------------------------------|:-------------------------:|:------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------|
| Open Source | X |  | All components open source, [MIT licensed code](https://github.com/CDL-Dryad/dryad-app)                                                       |
| Standards compliant | X |  | Dryad integrates with any SWORD-compliant repository                                                                                          |
| Pluggable Framework | X |  | Inherent extensibility for supporting additional protocols and metadata schemas                                                               |
| Flexible metadata schemas | X |  | Support Datacite metadata schema out-of-the-box, but can be configured to support any schema                                                  |
| Innovation | X |  | Our modular framework will make new feature development easier and quicker                                                                    |
| Mobile/responsive design | X | X | Built mobile-first, from the ground up, for better user experience                                                                            |
| Geolocation - Metadata | X | X | For applicable research outputs, we have an easy to use way to capture location of your datasets                                              |
| Persistent Identifers - ORCID | X | X | Dryad requires ORCID for login and allows for co-authors to attach their ORCID, allowing them to track their work                             |
| Persistent Identifers - DOIs | X | X | Dryad issues DOIs for all datasets, allowing researchers to track and get credit for their work                                               |
| Persistent Identifers - Funder Registry | X | X | Dryad tracks funder information using Crossref's Funder Registry, allowing researchers and funders to track their reasearch outputs           |
| Persistent Identifers - Research Organization Registry | X | X | Dryad tracks institutional affiliations with ROR IDs, allowing institutions to track their reasearch outputs                                  |
| Login - Shibboleth /OAuth2 | X | X | We offer easy single-sign with your campus credentials and ORCID account                                                                      |
| Versioning | X | X | Datasets can change. Dryad offers a quick way for you to upload new versions of your datasets and offer a simple process for tracking updates |
| Accessibility | X | X | The technology, design, and user workflows have all been built with accessibility in mind                                                     |
| Better user experience |  | X | Self-depositing made easy. Simple workflow, drag-and-drop upload, simple navigation, clean data publication pages, user dashboards            |
| Geolocation - Search |  | X | With GeoBlacklight, we can offer search by location                                                                                           |
| Robust Search |  | X | Search by subject, filetype, keywords, campus, location, etc.                                                                                 |
| Discoverability |  | X | Indexing by search engines including Google Dataset Search                                                                                    |
| Build Relationships |  | X | Many datasets are related to publications or other data. Dryad offers a quick way to describe these relationships                             |
| Supports Best Practices |  | X | Data publication can be confusing. But with Dryad, you can trust deposits are following best practices                                        |
| Data Metrics |  | X | See the reach of your datasets through standardized (Make Data Count) usage and download metrics                                              |
| Data Citations |  | X | Quick access to a well-formed citiation reference (with DOI) to every data publication. Easy for your peers to quickly grab                   |
| Open License |  | X | Dryad supports open Creative Commons licensing for all data deposits                                                                          |
| Support Data Reuse |  | X | Focus researchers on describing methods and explaining ways to reuse their datasets                                                           |
| Satisfies Data Availability Requirements |  | X | Many publishers and funders require researchers to make their data available. Dryad is an readily accepted and easy way to comply             |

## History

Dryad's original iteration launched in 2009 and was built upon the open-source DSpace repository software. In 2019, Dryad merged with Dash, a data publication service developed at the [University of California Curation Center](http://www.cdlib.org/uc3) (UC3), a program at [California Digital Library](http://www.cdlib.org) (CDL).
