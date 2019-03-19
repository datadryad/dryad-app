# Help

## [Why Use Dryad?](#why-use)

Dryad aims to make data publishing as **simple** and as **rewarding** as possible through a suite of services:

### Simple
- **Any field, any format**. Submit data in any file format from any research discipine. Share all of the data from a project in one place.
- **Integrated**. Dryad works with many publishers -- including Wiley, The Royal Society, and PLOS -- to integrate article and data submission, streamlining the submission process. Dryad can also make data privately available for peer review.
- **Open**. Dryad provides a single clear and best-practice option for terms of reuse (CC0).
- **Quality control and assistance**. Our curators will check your files before they are released, and help you follow best practices. You are encouraged to provide descriptive information that makes your data easier to discover and documentation (in the form of README files) to help ensure proper data reuse.
- **Flexible**. You have the ability to version your data publication to make updates or corrections.

### Rewarding
- **Increase the impact of your work**. You get an informative landing page to facilitate reuse of your data and a citable Digital Object Identifier (DOI). Each landing page is optimized for search engines and includes standardized usage metrics.
- **Straightforward compliance**. Submit your data to satisfy publisher and funder requirements for preservation and availability with a minimum of effort.
- **Stable and accessible**. Your data is preserved and available for the long term in a CoreTrustSeal-certified repository.
- **Networked**. Dryad is responsive to the needs of the researchers through its community of users and members, and is a participant in organizations such as BioSharing, DataCite and DataONE. You as a researcher benefit from, and contribute to, the work of these organizations by submitting to and using Dryad.
- **Community-led**. By publishing in Dryad, you are supporting a nonprofit membership organization committed to making data available for research and educational reuse. Modest, one-time Data Publishing Charges help ensure our sustainability.


## [Submission Process](#submission)

Before you begin, we recommend reviewing our best practices for creating reusable data publications (add link). 

General reminders and suggestions for publishing your data with Dryad:

- We accept all file formats, although it is good practice to share data using open formats. See the [UK Data Archive](http://www.data-archive.ac.uk/create-manage/format/formats-table) for a list of optimal file formats
- Any data submitted will be published under the CC0 license. We do not currently support any other license types, nor do we allow for restrictions on data access or use
- It is your responsibility to ensure your data are being shared responsibly and ethically. Please be careful about sharing sensitive data and ensure you are complying with institutional and governmental regulations
- When preparing your complete version of a dataset, remember to collate all relevant explantory documents and metadata. This includes relevant documentation necessary for the re-use and replication of your dataset (e.g., readme.txt files, formal metadata records, or other critical information)

If you need further assistance, consult our FAQ or contact us at <a href=mailto:help@datadryad.org>help@datadryad.org</a>.

Dryad has a REST API that allows for download and submission of data. Check out our [documentation](https://dash.ucop.edu/api/docs/index.html) as well as our [How-To Guide](https://github.com/CDL-Dryad/dryad/blob/master/stash_api/basic_submission.md)


### Metadata

Comprehensive data documentation (i.e. metadata) is the key to future understanding of data. Without a thorough description of the data file, the context in which the data were collected, the measurements that were made, and the quality of the data, it is unlikely that the data can be easily discovered, understood, or effectively used. 

Metadata is important not only to help people understand and make proper use of a data resource, but also to make the resource discoverable (for example, through internet searches or data indexing services). Read more about metadata in the [DataONE Primer on Data Management Best Practices](http://www.dataone.org/sites/all/documents/DataONE_BP_Primer_020212.pdf)
(PDF).

A complete list of our default metadata fields is below. Additional metadata can be uploaded alongside the dataset (e.g., as a readme.txt file). Our default metadata entry form is based on fields from the metadata schema of the DOI issuing agency, DataCite.

**Required fields**:

- Title : Title of the dataset. Make sure to be as descriptive as possible
- Author(s): Name, email address, institutional affliation of main researcher(s) involved in producing the data. If you include your [ORCID](http://orcid.org), we will request the ORCID registry auto-populate this publication on your ORCID profile
- Abstract: Short description of dataset

**Optional fields** (the more you describe your dataset, the wider the reach):

- Keyword(s) : Descriptive words that may help others discover your dataset. We recommend that you determine whether your discipline has an existing controlled vocabulary from which to choose your keywords. Please enter as many keywords as applicable
- Methods : Any technical or methodological information that may help others to understand how the data were generated (i.e. equipment/tools/reagents used, or procedures followed)
- Usage Notes : Any technical or methodological information that may help others determine how the data may be properly re-used, replicated, or re-analyzed
- Funding Information : Name of the funding organization that supported creation of the resource, including applicable grant number(s)
- Related Works : Use this field to indicate other resources that are associated with the data. Examples include publications, other datasets, code etc.
- Location information : Include the geo-coordinates or name of the location where your data were generated or the location that is the focus of your research

### Upload Methods

We have two different options for uploading your data.

- Upload directly from your computer: by using drag and drop or the upload button. We allow for 10gb of data per DOI to be uploaded this way.
- Upload from a server or the cloud: by entering the URL of the location where data are held on a server, or the sharing link for Box, Dropbox, or Google Drive. We allow for 100gb of data per DOI to be validated and uploaded this way.

Please note that you may only use one of these two upload methods per version, but you may do subsequent versions of your data publication and utilize different methods of upload this way.

### Curation

Once your data is submitted, Dryad [curators](/stash/about#staff) perform basic checks:

- Can the files be opened?
- Are they free of copyright restrictions?
- Do they appear to be free of sensitive data?
- Are the metadata and documentation complete and correct?

If Dryad curators identify any questions, problems, or areas for improvement, they will contact you directly via the email address associated with your account. You may contact the curation team for questions or consultations at <a href=mailto:curator@datadryad.org>curator@datadryad.org</a>

Upon curator approval, the Dryad DOI is officially registered and, if applicable, the Data Publishing Charge is invoiced.


### Publication and Citation

- We allow you to delay the publication of your data if for the purposes of having a related article under peer review.
- As soon as your data is public, we recommend citing and publicizing your work with your given DOI.
  - If there is an article or other publication related to your data, we recommend that the data be cited in the bibliography of the original publication so that the link between the publication and data is indexed by third party services.
- If you have edits, additional data, or subsequent related work we recommend versioning your data by using the "update" link. All versions of a dataset will be accessible, but the dataset DOI will always resolve to the newest version.
- For more details about publication with Dryad see our [Frequently Asked Questions (FAQ)](/stash/faq/)

## [Data Publishing Charges](#fees)

Dryad is a **nonprofit** organization that provides long-term access to its contents at no cost to users. We are able to provide free access to data due to financial support from members and data submitters. Dryad's Data Publishing Charges (DPCs) are designed to recover the core costs of curating and preserving data.
 
**Waivers** are granted for submissions originating from researchers based in countries [classified by the World Bank as low-income or lower-middle-income economies](http://data.worldbank.org/about/country-classifications/country-and-lending-groups).

**The base DPC per data submission is $120**. DPCs are invoiced upon curator approval/publication, unless:

- the submitter is based at a member institution (determined by login credentials), or
- an associated journal or publisher has an agreement with Dryad to sponsor the DPC (look up your journal here), or
- the submitter is based in a fee-waiver country (see above).

