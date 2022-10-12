<h1>Submission and Publication Process</h1>

<p>
    Data publishing includes describing and organizing your data in a way that makes it accessible and reusable to
    researchers. For an overview see our <a href="/docs/QuickstartGuideToDataSharing.pdf">Quick Start to Data Sharing</a>.
    Dryad’s process is outlined here, including links to our <a href="/stash/faq">Frequently Asked Questions</a> with
    information on particular topics and <a href="/stash/best_practices">recommendations for good data practices</a>. If
    you need further assistance, please contact us at <a href="mailto:help@datadryad.org">help@datadryad.org</a>.
</p>

<p>Ready to get started? <a href="/stash/">Log in</a> and go to "My Datasets" to begin your data submission now!</p>

<h2 id="login">Login</h2>

<p>
    Dryad requires an <a href="https://orcid.org">ORCID ID</a> for login. If you do not have an ORCID, you will have the
    opportunity to create a free, unique, identifier for yourself at the login page. Dryad uses ORCID so that we can
    authenticate and identify each individual researcher regardless of your route of entry to Dryad (i.e. through the
    website, through the API, through a journal integration, etc.). When datasets are published, they should appear in
    your ORCID profile along with articles and other works.
</p>

<p>
    For institutional members, we require a second form of authentication at login for campus single-sign-on. After you
    have logged in with your institutional credentials, Dryad ties together your ORCID and institutional affiliation so
    that you will not have to include this information a second time.
</p>

<p>
  Ready to get started? <a href="/stash/sessions/choose_login">Log in</a> and go to the "My Datasets" to begin your data
  submission now!
</p>

<h2 id="uploading">Uploading your data</h2>

<h3>Describe Your Dataset</h3>
<p>
    You will first be asked to enter metadata (information about your data). Check out our tips for complete and
    <a href="/stash/faq#metadata">comprehensive metadata</a>.  When you <a href="/stash/faq#upload-files">upload data files</a>,
    ensure that they meet our <a href="/stash/faq#files">file requirements</a> and are able to be opened, they do not
    contain sensitive information, and do not have licensing conflicts with <a href="/stash/faq#cc0">CC0</a>.
</p>

<p>
  Our duplicate submission detector will scan the first four words of the dataset title and, if those words match an
  existing dataset linked to the same submitting author, a pop-up will appear on the final page of the submission
  form to warn of a potential identical submission. If there is no risk of duplication, you can bypass the warning
  and proceed to submit.
</p>

<h3>Upload Files</h3>

<p>
  Dryad is a repository for the raw, unprocessed data that were used to support the conclusions presented in your
  article. We have partnered with <a href="https://zenodo.org/" target="_blank">Zenodo</a> to host
  software files and supplemental information uploaded to our site.
  Because non-data files are not always compatible with the CC0 license required by Dryad, submitters will have 
  the opportunity to choose a  separate license for their code at the final stage of the submission process. 
  All files uploaded as "Supplemental Information" will be licensed under CCBY. 
</p>

<img src="/images/dryad_upload.png" alt="Screenshot of image upload" />

<p>
  The “Data” category should include your primary, underlying data that has not been processed for use. Common file
  types include .csv, .xlsx, .txt and compressed file archives: TAR.GZ, 7Z, ZIP. 
</p>

<p>
  We require that a README file is uploaded to this category to clearly define all variables, across all data files 
  contained within the submission. The file name must begin with “README” in all caps (i.e. README_file.md). 
  For guidance, please use our <a href="https://datadryad.org/docs/README.md"> README template</a>
  to ensure all necessary information is included. 
</p>

<p>
  The “Software” category is reserved for code packages (.R files, Python scripts, etc.) that outline
  all steps in processing and analyzing your data, ensuring reproducibility. Files uploaded to this
  category will be evaluated and hosted by Zenodo. Because non-data files are not always compatible
  with the CC0 license required by Dryad, you will have the opportunity to choose a separate license
  for your code at the final stage of the submission process
</p>

<p>
  The “Supplemental information” can include figures, supporting tables, appendices, etc. related
  to your research article. Please do not upload supplementary material already present within the
  manuscript that will appear in the published article.
</p>

<p>
    For more information about our Zenodo integration check
    out <a href="/stash/faq#zenodo-integrate">our FAQ</a>.
</p>

<h3>Tabular Data Validator</h3>

<p>
For all data files uploaded to Dryad in CSV, XLS, XLSX formats (5MB or less), a report will be automatically generated by our tabular data validator, an integration with the <a href="https://frictionlessdata.io/">Frictionless</a> python tool. This integration allows for automated data validation, focused on the format and structure of tabular data files, prior to our curation services.
</p>

<p>
If any issues are identified, a window with instructions will appear on the
"Upload Files" page and a link to a detailed report will be provided in the
"Tabular Data Check" column. The report will help guide you in locating and
evaluating errors in your tabular data. Any files flagged in the report will
need to be removed, edited, and reuploaded prior to proceeding with the
submission process.
</p>

<p>
If your files have been accessed and are acceptable, "Passed" will appear in the
"Tabular Data Check" column and no report will be generated. If your files have
not been checked by the validator due to size or type, the "Tabular Data Check"
column will be empty. In either scenario, no changes will be required and you
may proceed with the submission process.
</p>

<p>
If you have questions or require assistance, contact <a href="mailto:help@datadryad.org">help@datadryad.org</a>.
</p>

<p>
Learn more about the Frictionless Data project at the <a href="https://frictionlessdata.io/">Open Knowledge
Foundation</a>. 
</p>

<h3>Review and Submit</h3>

<p>
  On the final page of the submission form, you’ll have the opportunity to review that your
  metadata is correct and check the required acknowledgments to confirm payment of the data
  publication charge.
</p>

<p>
  If you are affiliated with a member institution or your related article is associated with a sponsoring
  journal title, the option to select the acknowledgment will not be available and a statement
  below will appear to confirm who is sponsoring the data publication charge.
</p>

<p>
  If you prefer that your data remain private during the peer review process, select <a href="/stash/faq#ppr">Private for Peer Review</a>
  on the final page of the submission form. While in this status, your submission will not enter
  our curation process or publish until the checkbox for this option is deselected or you contact
  us to update the status of your submission.
</p>

<p>If you have questions or require assistance, contact <a href="mailto:help@datadryad.org">help@datadryad.org</a>.</p>

<h2 id="curation">Dataset Curation</h2>
<p>
    We will review your data ensuring it meets our <a href="/stash/faq#curation">curation requirements</a>. If we have
    questions we’ll get in touch with you. For more information check out <a href="/stash/faq">our FAQ</a>.
</p>

<h2 id="publication">Dataset Publication</h2>

<p>
  Once your submission has been reviewed and approved by our team of curators, you will receive a notification of 
  publication via email and your dataset will be made publicly available. The DOI <a href="/stash/faq#cite">provided 
  to you</a> upon submission will remain unchanged.
</p>

<p>
  If the data publication charge is not covered by a journal, your institution, or if you are not eligible for a 
  fee waiver, <a href="/stash/faq#cost">an invoice</a> will be generated and sent upon publication.
</p>

<p>
  Datasets can be updated via your Dryad dashboard. Please note, any edits made will create a new version of your 
  submission. Only the most recent version of your dataset will be packaged and available for download via the 
  ‘Download Dataset’ button.
</p>
