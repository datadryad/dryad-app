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
<p>You may find our <a href="/stash/faq">FAQ</a> and best practices guidance helpful as you get started. Log in and go to "My Datasets" to begin your data submission now!</p>

<h2>Submission Process<a name="submission"></a></h2>

<p>Before you begin, we recommend reviewing our best practices for creating reusable data publications or, if you're in a hurry, our quickstart guide to data sharing <strong>(add links)</strong>.</p>

<p>General reminders and suggestions for publishing your data with Dryad:</p>
<ul>
<li><strong>We accept all file formats, although it is good practice to share data using open formats</strong>. See the <a href="http://www.data-archive.ac.uk/create-manage/format/formats-table">UK Data Archive</a> for a list of optimal file formats</li>
  <li><strong>Any data submitted will be published under the CC0 license</strong>. We do not currently support any other license types, nor do we allow for restrictions on data access or use</li>
<li><strong>It is your responsibility to ensure your data are being shared responsibly and ethically</strong>. Please be careful about sharing sensitive data and ensure you are complying with institutional and governmental regulations</li>
<li><strong>When preparing your complete version of a dataset, remember to collate all relevant explantory documents and metadata</strong>. This includes relevant documentation necessary for the re-use and replication of your dataset (e.g., readme.txt files, formal metadata records, or other critical information)</li>
</ul>

<p>Dryad has a REST API that allows for download and submission of data. Check out our <a href="https://dash.ucop.edu/api/docs/index.html">documentation</a> as well as our <a href="https://github.com/CDL-Dryad/dryad/blob/master/stash_api/basic_submission.md">How-To Guide</a></p>

<p>If you need further assistance, consult our <a href="/stash/faq">FAQ</a> or contact us at <a href=mailto:help@datadryad.org>help@datadryad.org</a>. Log in and go to "My Datasets" to begin your data submission now!</p>

<p>View more information about:</p>
<ul>
  <li><a href="#metadata">Metadata</a></li>
  <li><a href="#upload-methods">Upload methods</a></li>
  <li><a href="#curation">Curation</a></li>
  <li><a href="#citation">Publication and citation</a></li>
  </ul>

<h3>Metadata<a name="metadata"></a></h3>

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

<h3 id="upload-methods">Upload Methods</h3>
<p>We have two different options for uploading your data.</p>
<ul>
<li>Upload directly from your computer: by using drag and drop or the upload button. We allow for 10gb of data per DOI to be uploaded this way.</li>
<li>Upload from a server or the cloud: by entering the URL of the location where data are held on a server, or the sharing link for Box, Dropbox, or Google Drive. We allow for 300gb (in a URL or dispersed through many URLs) of data per DOI to be validated and uploaded this way.</li>
</ul>
<p>Please note that you may only use one of these two upload methods per version, but you may do subsequent versions of your data publication and utilize different methods of upload this way.</p>

<h3>Curation<a name="curation"></a></h3>
<p><strong>What is data curation?</strong> Data curators review and enrich research data to help make it <a href="https://www.force11.org/group/fairgroup/fairprinciples">Findable, Accessible, Interoperable, and Reusable (FAIR)</a>. According to the <a href="https://datacurationnetwork.org/about/our-mission/">Data Curation Network<a> (of which Dryad is a member),<blockquote>Data curation enables data discovery and retrieval, maintains data quality, adds value, and provides for re-use over time through activities including authentication, archiving, metadata creation, digital preservation, and transformation.</blockquote></p>
<p>Dryad has a team of <a href="/stash/about#staff">professional curators</a> who check every submission to ensure the validity of files and metadata. Once your data is submitted, Dryad curators perform basic checks:</p>
<ul>
<li>Can the files be opened?</li>
<li>Are they free of copyright restrictions?</li>
<li>Do they appear to be free of sensitive data?</li>
<li>Are the metadata and documentation complete and correct?</li>
<li>Is adequate description provided to ensure reusability?</li>
</ul>
<p>If Dryad curators identify questions, problems, or areas for improvement, they will contact you directly via the email address associated with your submission. You may contact the curation team for questions or consultations at <a href=mailto:curator@datadryad.org>curator@datadryad.org</a></p>
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

<p>So, you want to share your research data in Dryad, but are unsure where to start or what you 'should' share? Don't worry, it's not always clear how to craft a dataset with reusability in mind.</p>

<p>We want to help you share your research with the scientific community to increase its <a href="https://peerj.com/articles/175/">visibility</a> and foster collaborations. The following guidelines will help make your Dryad datasets as interpretable and reusable as possible.</p>

<p>No time to dig into the details? Check out our <a href="https://datadryad.org/pages/quickstart-guide">quickstart guide to data sharing</a>.</p>

<p class="toc_title">Contents:</p>
<ul>
  <li><a href="#gather">Gather all relevant data needed for reanalysis</a></li>
  <li><a href="#shareable">Make sure your data are shareable</a></li>
  <li><a href="#accessible">Make sure your data are accessible</a></li>
  <li><a href="#organize">Organize files in a logical schema</a></li>
  <li><a href="#describe">Describe your dataset in a README file</a></li>
  <li><a href="#examples">Examples of good reusability practices</a></li>
  <li><a href="#resources">Further resources</a></li>
</ul>



<h3 id="gather">Gather all relevant data needed for reanalysis</h3>

<ul>
<li><strong>Consider all of the information necessary for one to reuse your dataset and replicate the analyses in your publication</strong>. Gather and organize everything--this may include experimental method details, raw data files, organized data tables, scripts, data visualizations, and statistical output. There are often several levels of data processing involved in a project, and it is important to provide adequate detail. That said, don't hesitate to edit out superfluous or ambiguous content that would confuse others.</li>
<li><strong>Unprocessed and processed data:</strong> Providing both unprocessed and processed data can be valuable for re-analysis, assuming the data are of a reasonable size. Including unprocessed raw digital data from a recording instrument or database ensures that no details are lost, and any issues in the processing pipeline can be discovered and rectified. Processed data are cleaned, formatted, organized and ready for reuse by others. </li>
<li><strong>Code:</strong> Programming scripts communicate to others all of the steps in processing and analysis. Including them ensures that your results are reproducible by others. Informative comments throughout your code will help future users understand its logic.</li>
<li><strong>External resources:</strong> Links to associated data stored in other data repositories, code in software repositories, and associated publications can be included in "Related works".</li>
</ul>


<h3>Make sure your data are shareable<a name="shareable"></a></h3>

<ul>
<li><strong>All files submitted to Dryad must abide by the terms of the <a href="https://creativecommons.org/publicdomain/zero/1.0/">Creative Commons Zero (CC0 1.0)</a></strong>. Under these terms, the author releases the data to the public domain. 
<ul><li>Review all files and ensure they conform to <code>CC0</code> terms and are not covered by copyright claims or other terms-of-use. We cannot archive any files that contain licenses incompatible with <code>CC0</code> (<code>GNU GPL, MIT, CC-BY,</code> etc.), but we can link to content in a dedicated software repository (Github, Zenodo, Bitbucket, or CRAN, etc.). </li>
<li>For more information on <a href="https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/">why Dryad uses <code>CC0</code></a>, and <a href="https://blog.datadryad.org/2017/09/11/some-dos-and-donts-for-cc0/">some dos and don'ts for <code>CC0</code></a></li></ul></li>
<li>Human subjects data must be properly anonymized and prepared under applicable legal and ethical guidelines (see tips for <a href="https://datadryad.org/pages/humanSubjectsData">human subjects data</a>)</li>
<li>If you work with vulnerable or endangered species, it may be necessary to mask location to prevent any further threat to the population. Please review our recommendations for responsibly sharing data collected from vulnerable species. (see tips <a href="https://datadryad.org/pages/endangeredSpecies">endangered species data</a> ).</li>
</ul>




<h3>Make sure your data are accessible<a name="accessible"></a></h3>

<ul>
<li>To maximize accessibility, reusability and preservability, share date in non-proprietary <a href="https://en.wikipedia.org/wiki/Open_format">open formats</a> when possible (see <a href="#formats">preferred formats</a>). This ensures your data will be accessible by most people.</li>
<li>Review files for errors. Common errors include missing data, misnamed files, mislabeled variables, incorrectly formatted values, and corrupted file archives. It may be helpful to run data validation tools before sharing. For example, if you are working with tabular datasets, a service like <a href="https://goodtables.io/">goodTables</a> can identify missing data and data type formatting problems.</li>
<li>Files compression may be necessary to reduce large file sizes or directories of files. Files can be bundled together in compressed file archives (<code>.zip, .7z, .tar.gz</code>). If you have a large directory of files, and there is a logical way to split it into subdirectories and compress those, we encourage you to do so. We recommend not exceeding 10GB each.</li>
</ul>


<h4>Preferred file formats<a name="formats"></a></h4>

<p>Dryad welcomes the submission of <em>data in multiple formats</em> to enable various reuse scenarios. For instance, Dryad's preferred format for tabular data is CSV, however, an Excel spreadsheet may optimize reuse in some cases. Thus, Dryad accepts more than just the preservation-friendly formats listed below.</p>

<ul>
<li><strong>Text</strong>:
<ul><li>README files should be in plain text format (<code>ASCII, UTF-8</code>)</li>
<li>Comma-separated values (<code>CSV</code>) for tabular data</li>
<li>Semi-structured plain text formats for non-tabular data (e.g., protein sequences)</li>
<li>Structured plain text (<code>XML, JSON</code>)</li></ul></li>
<li><strong>Images</strong>: <code>PDF, JPEG, PNG, TIFF, SVG</code></li>
<li><strong>Audio</strong>: <code>FLAC, AIFF, WAV, MP3, OGG</code></li>
<li><strong>Video</strong>: <code>AVI, MPEG, MP4</code></li>
<li><strong>Compressed file archive</strong>: <code>TAR.GZ, 7Z, ZIP</code></li>
</ul>


<h3 id="organize">Organize files in a logical schema</h3>

<h4>File naming</h4>

<p>Name files and directories in a consistent and descriptive manner. Avoid vague and ambiguous filenames. Filenames should be concise, informative, and unique (see Stanford's <a href="https://library.stanford.edu/research/data-management-services/data-best-practices/best-practices-file-naming">best practices for file naming</a>).</p>

<p>Avoid blank spaces and special characters (<code>' '!@#$%^&amp;"</code>) in filenames because they can be problematic for computers to interpret. Use a common letter case pattern because they are easily read by both machines and people:</p>

<ul>
<li>Kebab-case: <code>The-quick-brown-fox-jumps-over-the-lazy-dog.txt</code></li>
<li>CamelCase: <code>TheQuickBrownFoxJumpsOverTheLazyDog.txt</code></li>
<li>Snake_case: <code>The_quick_brown_fox_jumps_over_the_lazy_dog.txt</code></li>
</ul>

<p>Include the following information when naming files:</p>

<ul>
<li>Author surname</li>
<li>Date of study</li>
<li>Project name</li>
<li>Type of data or analysis</li>
<li>File extension (<code>.csv, .txt, .R, .xls, .tar.gz, etc.</code>)</li>
</ul>


<img src="dataset-structure.png" alt="Dataset organization">



<h3 id="describe">Describe your dataset in a README file</h3>

<p>Provide a clear and concise description of all relevant details about data collection, processing, and analysis in a README document. This will help others interpret and reanalyze your dataset.</p>

<p>Plain text README files are recommended, however, PDF is acceptable when formatting is important.</p>

<p>If you included a README in a compressed archive of files, please also upload it externally in the README section so that users are aware of the contents before downloading. </p>

<p>Cornell University's Research Data Management Service Group has created an excellent <a href="https://data.research.cornell.edu/content/readme">README template</a></p>

<h4>Details to include:</h4>

<ul>
<li>Citation(s) of your published research derived from these data</li>
<li>Citation(s) of associated datasets stored elsewhere (include URLs)</li>
<li>Project name and executive summary</li>
<li>Contact information regarding analyses</li>
<li>Methods of data processing and analysis</li>
<li>Describe details that may influence reuse or replication efforts</li>
<li>De-identification procedures for sensitive human subjects or endangered species data</li>
<li>Specialized software (include version and developer's web address) used for analyses and file compression. If proprietary, include open source alternatives.</li>
<li>Description of file(s):
<ul><li>file/directory structure</li>
<li>type(s) of data included (categorical, time-series, human subjects, etc.)</li>
<li>relationship to the tables, figures, or sections within associated publication</li>
<li>key of definitions of variable names, column headings and row labels, data codes (including missing data), and measurement units</li></ul></li>
</ul>




<h4>Log in and go to "My Datasets" to start your submission now!</h4>


<h3 id="examples">Examples of good reusability practices</h3>

<ul>
<li>Gallo T, Fidino M, Lehrer E, Magle S (2017) Data from: Mammal diversity and metacommunity dynamics in urban green spaces: implications for urban wildlife conservation. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.9mf02">https://doi.org/10.5061/dryad.9mf02</a></li>
<li>Rajon E, Desouhant E, Chevalier M, Débias F, Menu F (2014) Data from: The evolution of bet hedging in response to local ecological conditions. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.g7jq6">https://doi.org/10.5061/dryad.g7jq6</a></li>
<li>Drake JM, Kaul RB, Alexander LW, O'Regan SM, Kramer AM, Pulliam JT, Ferrari MJ, Park AW (2015) Data from: Ebola cases and health system demand in Liberia. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.17m5q">https://doi.org/10.5061/dryad.17m5q</a></li>
<li>Wall CB, Mason RAB, Ellis WR, Cunning R, Gates RD (2017) Data from: Elevated pCO2 affects tissue biomass composition, but not calcification, in a reef coral under two light regimes. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.5vg70.3">https://doi.org/10.5061/dryad.5vg70.3</a></li>
<li>Kriebel R, Khabbazian M, Sytsma KJ (2017) Data from: A continuous morphological approach to study the evolution of pollen in a phylogenetic context: an example with the order Myrtales. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.j17pm.2">https://doi.org/10.5061/dryad.j17pm.2</a></li>
</ul>


<h3 id="resources">Further resources</h3>

<ul>
<li>Institutional data librarians are an outstanding resource. Check with your university library's data management services team.</li>
<li><a href="https://data.research.cornell.edu/content/readme">Cornell University Research Data Management Service Group's Guide to writing "readme" style metadata</a></li>
<li><a href="https://datadryad.org/pages/faq#info-cc0">Why Dryad uses Creative Commons Zero</a></li>
<li><a href="https://www.dataone.org/sites/all/documents/DataONE_BP_Primer_020212.pdf">DataONE Primer on Data Management Best Practices</a></li>
<li><a href="http://blogs.lse.ac.uk/impactofsocialsciences/2015/02/09/data-versioning-open-science/">Introduction to Open Science: Why data versioning and data care practices are key for science and social science</a></li>
<li><a href="https://www.force11.org/group/fairgroup/fairprinciples">Making data Findable, Accessible, Interoperable, and Reusable (FAIR)</a></li>
<li><a href="https://try.goodtables.io/">goodTables - free online service for tabular data validation</a></li>
<li><a href="http://www.tandfonline.com/doi/full/10.1080/00031305.2017.1375989">Data organization in spreadsheets</a></li>
</ul>


