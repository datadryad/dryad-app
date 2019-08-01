<h1>Submission Process</h1>

<p>Before you begin, we recommend reviewing our best practices for creating reusable data publications or, if you're in a hurry, our quickstart guide to data sharing <strong>(add links)</strong>.</p>

<p>General reminders and suggestions for publishing your data with Dryad:</p>
<ul>
<li><strong>We accept all file formats, although it is good practice to share data using open formats</strong>. See the <a href="http://www.data-archive.ac.uk/create-manage/format/formats-table">UK Data Archive</a> for a list of optimal file formats</li>
  <li><strong>Any data submitted will be published under the CC0 license</strong>. We do not currently support any other license types, nor do we allow for restrictions on data access or use</li>
<li><strong>It is your responsibility to ensure your data are being shared responsibly and ethically</strong>. Please be careful about sharing sensitive data and ensure you are complying with institutional and governmental regulations</li>
<li><strong>When preparing your complete version of a dataset, remember to collate all relevant explantory documents and metadata</strong>. This includes relevant documentation necessary for the re-use and replication of your dataset (e.g., readme.txt files, formal metadata records, or other critical information)</li>
</ul>

<p>Dryad has a REST API that allows for download and submission of data. Check out our <a href="https://dryad-stg.cdlib.org/api/docs/">documentation</a> as well as our <a href="https://github.com/CDL-Dryad/dryad/blob/master/stash_api/basic_submission.md">How-To Guide</a></p>

<p>If you need further assistance, consult our <a href="/stash/faq">FAQ</a> or contact us at <a href=mailto:help@datadryad.org>help@datadryad.org</a>. Log in and go to "My Datasets" to begin your data submission now!</p>

<p>View more information about:</p>
<ul>
  <li><a href="#login">Login</a></li>
  <li><a href="#metadata">Metadata</a></li>
  <li><a href="#upload-methods">Upload methods</a></li>
  <li><a href="#curation">Curation</a></li>
  <li><a href="#citation">Publication and citation</a></li>
  </ul>

<h2>Login<a name="login"></a></h2>

<p>Dryad requires an ORCID ID (https://orcid.org) for login. If you do not have an ORCID, you will have the opportunity to create a free, unique, identifier for yourself at the login page. Dryad uses ORCID so that we can authenticate and identify each individual researcher regardless of your route of entry to Dryad (i.e. through the website, through the API, through a journal integration, etc.). When datasets are published, they should appear in your ORCID profile along with articles and other works. For institutional members, we require a second form of authentication at login for campus single-sign-on. After you have logged in with your institutional credentials, Dryad ties together your ORCID and institutional affiliation so that you will not have to include this information a second time.</p>

<h2>Metadata<a name="metadata"></a></h2>

<p>Comprehensive data documentation (i.e. metadata) is the key to future understanding of data. Without a thorough description of the data file, the context in which the data were collected, the measurements that were made, and the quality of the data, it is unlikely that the data can be easily discovered, understood, or effectively used. </p>

<p>Metadata is important not only to help people understand and make proper use of a data resource, but also to make the resource discoverable (for example, through internet searches or data indexing services). Read more about metadata in the <a href="http://www.dataone.org/sites/all/documents/DataONE_BP_Primer_020212.pdf">DataONE Primer on Data Management Best Practices</a> (PDF).</p>

<p>A complete list of our default metadata fields is below. Additional metadata can be uploaded alongside the dataset (e.g., as a readme.txt file). Our default metadata entry form is based on fields from the metadata schema of the DOI issuing agency, DataCite.</p>

<p><strong>Required fields</strong>:</p>
<ul>
<li>Title: Title of the dataset. Make sure to be as descriptive as possible</li>
<li>Author(s): Name, email address, institutional affliation of main researcher(s) involved in producing the data. If you include your <a href="http://orcid.org">ORCID</a>, we will request the ORCID registry auto-populate this publication on your ORCID profile</li>
<li>Abstract: Short description of dataset</li>
</ul>
<p><strong>Optional fields</strong> (the more you describe your dataset, the wider the reach):</p>
<ul>
<li>Keyword(s): Descriptive words that may help others discover your dataset. We recommend that you determine whether your discipline has an existing controlled vocabulary from which to choose your keywords. Please enter as many keywords as applicable</li>
<li>Methods: Any technical or methodological information that may help others to understand how the data were generated (i.e. equipment/tools/reagents used, or procedures followed)</li>
<li>Usage Notes : Any technical or methodological information that may help others determine how the data may be properly re-used, replicated, or re-analyzed</li>
<li>Funding Information: Name of the funding organization that supported creation of the resource, including applicable grant number(s)</li>
<li>Related Works: Use this field to indicate other resources that are associated with the data. Examples include publications, other datasets, code etc.</li>
<li>Location information: Include the geo-coordinates or name of the location where your data were generated or the location that is the focus of your research</li>
</ul>

<h2 id="upload-methods">Upload Methods</h2>
<p>We have two different options for uploading your data.</p>
<ul>
<li>Upload directly from your computer: by using drag and drop or the upload button. We allow for 10gb of data per DOI to be uploaded this way.</li>
<li>Upload from a server or the cloud: by entering the URL of the location where data are held on a server, or the sharing link for Box, Dropbox, or Google Drive. We allow for 300gb (in a URL or dispersed through many URLs) of data per DOI to be validated and uploaded this way.</li>
</ul>
<p>Please note that you may only use one of these two upload methods per version, but you may do subsequent versions of your data publication and utilize different methods of upload this way.</p>

<h2>Curation<a name="curation"></a></h2>
<p><strong>What is data curation?</strong> Data curators review and enrich research data to help make it <a href="https://www.force11.org/group/fairgroup/fairprinciples">Findable, Accessible, Interoperable, and Reusable (FAIR)</a>. According to the <a href="https://datacurationnetwork.org/about/our-mission/">Data Curation Network<a> (of which Dryad is a member),<blockquote>Data curation enables data discovery and retrieval, maintains data quality, adds value, and provides for re-use over time through activities including authentication, archiving, metadata creation, digital preservation, and transformation.</blockquote></p>
<p>Dryad has a team of <a href="/stash/our_staff">professional curators</a> who check every submission to ensure the validity of files and metadata. Once your data is submitted, Dryad curators perform basic checks:</p>
<ul>
<li>Can the files be opened?</li>
<li>Are they free of copyright restrictions?</li>
<li>Do they appear to be free of sensitive data?</li>
<li>Are the metadata and documentation complete and correct?</li>
<li>Is adequate description provided to ensure reusability?</li>
</ul>
<p>If Dryad curators identify questions, problems, or areas for improvement, they will contact you directly via the email address associated with your submission. You may contact the curation team for questions or consultations at <a href=mailto:curator@datadryad.org>curator@datadryad.org</a></p>
<p>Upon curator approval, the Dryad DOI is officially registered and, if applicable, the <a href="#fees">Data Publishing Charge</a> is invoiced.</p>

<h2>Publication and Citation<a name="citation"></a></h2>
<ul>
<li>We allow you to delay the publication of your data for the purposes of having a related article under peer review.</li>
<li>As soon as your data is public, we recommend citing and publicizing your work with your given DOI.
<ul>
<li>Recommended citation format is provided on the dataset landing page.</li>
<li>If there is an article or other publication related to your data, we recommend that the data be cited in the references of the original publication so that the link between the publication and data is indexed by third-party services.</li>
</ul></li>
<li>If you have edits, additional data, or subsequent related work we recommend versioning your data by using the &quot;update&quot; link. All versions of a dataset will be accessible, but the dataset DOI will always resolve to the newest version.</li>
<li>For more details about publication with Dryad see our <a href="/stash/faq/">Frequently Asked Questions (FAQ)</a></li>
</ul>