<h1>Help</h1>

<h2>Why Use Dryad?<a name="why-use-dryad"></a></h2>

<p>Dryad aims to make data publishing as <strong>simple</strong> and as <strong>rewarding</strong> as possible through a suite of services:</p>

<h3 id="simple">Simple</h3>
<ul>
<li><strong>Any field, any format</strong>. Submit data in any file format from any research discipine. Share all of the data from a project in one place.</li>
<li><strong>Integrated</strong>. Dryad works with many publishers -- including Wiley, The Royal Society, and PLOS -- to integrate article and data submission, streamlining the submission process. Dryad can also make data privately available for peer review.</li>
<li><strong>Open</strong>. Dryad provides a single clear and best-practice option for terms of reuse (CC0).</li>
<li><strong>Quality control and assistance</strong>. Our curators will check your files before they are released, and help you follow best practices. You are encouraged to provide descriptive information that makes your data easier to discover and documentation (in the form of README files) to help ensure proper data reuse.</li>
<li><strong>Flexible</strong>. You have the ability to version your data publication to make updates or corrections.</li>
</ul>

<h3 id="rewarding">Rewarding</h3>
<ul>
<li><strong>Increase the impact of your work</strong>. You get an informative landing page to facilitate reuse of your data and a citable Digital Object Identifier (DOI). Each landing page is optimized for search engines and includes standardized usage metrics.</li>
<li><strong>Straightforward compliance</strong>. Submit your data to satisfy publisher and funder requirements for preservation and availability with a minimum of effort.</li>
<li><strong>Stable and accessible</strong>. Your data is preserved and available for the long term in a CoreTrustSeal-certified repository.</li>
<li><strong>Networked</strong>. Dryad is responsive to the needs of the researchers through its community of users and members, and is a participant in organizations such as BioSharing, DataCite and DataONE. You as a researcher benefit from, and contribute to, the work of these organizations by submitting to and using Dryad.</li>
<li><strong>Community-led</strong>. By publishing in Dryad, you are supporting a nonprofit membership organization committed to making data available for research and educational reuse. Modest, one-time Data Publishing Charges help ensure our sustainability.</li>
</ul>

<h2>Submission Process<a name="submission"></a></h2>

<p>Before you begin, we recommend reviewing our best practices for creating reusable data publications <strong>(add link)</strong>. </p>

<p>General reminders and suggestions for publishing your data with Dryad:</p>
<ul>
<li>We accept all file formats, although it is good practice to share data using open formats. See the <a href="http://www.data-archive.ac.uk/create-manage/format/formats-table">UK Data Archive</a> for a list of optimal file formats</li>
<li>Any data submitted will be published under the CC0 license. We do not currently support any other license types, nor do we allow for restrictions on data access or use</li>
<li>It is your responsibility to ensure your data are being shared responsibly and ethically. Please be careful about sharing sensitive data and ensure you are complying with institutional and governmental regulations</li>
<li>When preparing your complete version of a dataset, remember to collate all relevant explantory documents and metadata. This includes relevant documentation necessary for the re-use and replication of your dataset (e.g., readme.txt files, formal metadata records, or other critical information)</li>
</ul>

<p>If you need further assistance, consult our FAQ or contact us at <a href=mailto:help@datadryad.org>help@datadryad.org</a>.</p>

<p>Dryad has a REST API that allows for download and submission of data. Check out our <a href="https://dash.ucop.edu/api/docs/index.html">documentation</a> as well as our <a href="https://github.com/CDL-Dryad/dryad/blob/master/stash_api/basic_submission.md">How-To Guide</a></p>

<h3>Metadata<a name="metadata"></a></h3>

<p>Comprehensive data documentation (i.e. metadata) is the key to future understanding of data. Without a thorough description of the data file, the context in which the data were collected, the measurements that were made, and the quality of the data, it is unlikely that the data can be easily discovered, understood, or effectively used. </p>

<p>Metadata is important not only to help people understand and make proper use of a data resource, but also to make the resource discoverable (for example, through internet searches or data indexing services). Read more about metadata in the <a href="http://www.dataone.org/sites/all/documents/DataONE_BP_Primer_020212.pdf">DataONE Primer on Data Management Best Practices</a> (PDF).</p>

<p>A complete list of our default metadata fields is below. Additional metadata can be uploaded alongside the dataset (e.g., as a readme.txt file). Our default metadata entry form is based on fields from the metadata schema of the DOI issuing agency, DataCite.</p>

<p><strong>Required fields</strong>:</p>
<ul>
<li>Title : Title of the dataset. Make sure to be as descriptive as possible</li>
<li>Author(s): Name, email address, institutional affliation of main researcher(s) involved in producing the data. If you include your <a href="http://orcid.org">ORCID</a>, we will request the ORCID registry auto-populate this publication on your ORCID profile</li>
<li>Abstract: Short description of dataset</li>
</ul>
<p><strong>Optional fields</strong> (the more you describe your dataset, the wider the reach):</p>
<ul>
<li>Keyword(s) : Descriptive words that may help others discover your dataset. We recommend that you determine whether your discipline has an existing controlled vocabulary from which to choose your keywords. Please enter as many keywords as applicable</li>
<li>Methods : Any technical or methodological information that may help others to understand how the data were generated (i.e. equipment/tools/reagents used, or procedures followed)</li>
<li>Usage Notes : Any technical or methodological information that may help others determine how the data may be properly re-used, replicated, or re-analyzed</li>
<li>Funding Information : Name of the funding organization that supported creation of the resource, including applicable grant number(s)</li>
<li>Related Works : Use this field to indicate other resources that are associated with the data. Examples include publications, other datasets, code etc.</li>
<li>Location information : Include the geo-coordinates or name of the location where your data were generated or the location that is the focus of your research</li>
</ul>

<h3 id="upload-methods">Upload Methods</h3>
<p>We have two different options for uploading your data.</p>
<ul>
<li>Upload directly from your computer: by using drag and drop or the upload button. We allow for 10gb of data per DOI to be uploaded this way.</li>
<li>Upload from a server or the cloud: by entering the URL of the location where data are held on a server, or the sharing link for Box, Dropbox, or Google Drive. We allow for 100gb of data per DOI to be validated and uploaded this way.</li>
</ul>
<p>Please note that you may only use one of these two upload methods per version, but you may do subsequent versions of your data publication and utilize different methods of upload this way.</p>

<h3>Curation<a name="curation"></a></h3>
<p>Once your data is submitted, Dryad <a href="/stash/about#staff">curators</a> perform basic checks:</p>
<ul>
<li>Can the files be opened?</li>
<li>Are they free of copyright restrictions?</li>
<li>Do they appear to be free of sensitive data?</li>
<li>Are the metadata and documentation complete and correct?</li>
</ul>
<p>If Dryad curators identify any questions, problems, or areas for improvement, they will contact you directly via the email address associated with your account. You may contact the curation team for questions or consultations at <a href=mailto:curator@datadryad.org>curator@datadryad.org</a></p>
<p>Upon curator approval, the Dryad DOI is officially registered and, if applicable, the <a href="#fees">Data Publishing Charge</a> is invoiced.</p>

<h3>Publication and Citation<a name="citation"></a></h3>
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


<h2>Data Publishing Charges<a name="fees"></a></h2>
<p>Dryad is a <strong>nonprofit</strong> organization that provides long-term access to its contents at no cost to users. We are able to provide free access to data due to financial support from members and data submitters. Dryad's Data Publishing Charges (DPCs) are designed to recover the core costs of curating and preserving data.</p>
<p><strong>Waivers</strong> are granted upon request (<a href=mailto:help@datadryad.org>help@datadryad.org</a>) for submissions originating from researchers based in countries <a href="http://data.worldbank.org/about/country-classifications/country-and-lending-groups">classified by the World Bank as low-income or lower-middle-income economies</a>.</p>
<p><strong>The base DPC per data submission is $120</strong>. DPCs are invoiced upon curator approval/publication, unless:</p>
<ul>
<li>the submitter is based at a member institution (determined by login credentials), or</li>
<li>an associated journal or publisher has an agreement with Dryad to sponsor the DPC, or</li>
<li>the submitter is based in a fee-waiver country (see above).</li>
</ul>
<h3 id="overage-fees">Overage fees</h3>
<p>For submissions without a sponsor or waiver, Dryad charges excess storage fees for data totaling over 50GB. For data packages in excess of 50GB, submitters will be charged $50 for each additional 10GB, or part thereof. (Submissions between 50 and 60GB = $50, between 60 and 70GB = $100, and so on).</p>


<h2>Best practices for creating reusable data publications<a name="best-practices"></a></h2>


