# Submission walkthrough

Before you begin a submission, please ensure your submission meets [our requirements](/stash/requirements) and follows [good data practices](/stash/best_practices). After your submission is complete, your dataset will be [curated and published](/stash/process). 

Ready to get started? [Log in](/stash/sessions/choose_login) and go to "My datasets" to begin your data submission now!


## Preparing your data

Data publishing includes describing and organizing your data in a way that makes it accessible and reusable. We recommend the use of [good data practices](/stash/best_practices), including descriptive names for file names and table headings, and a logical file organization.

Assemble all data files together. Where possible, data should be shared in [an open file format](/stash/requirements#preferred-file-formats) so that proprietary software is not required to view or use the files.

* All files should be able to be opened without any passcode restrictions.
* All information needs to be in English.
* No Personal Health Information or sensitive data can be included. See <a href="/docs/HumanSubjectsData.pdf">tips for human subjects data <span class="pdfIcon" role="img" aria-label=" (PDF)"/></a> and <a href="/docs/EndangeredSpeciesData.pdf">tips for sensitive species data<span class="pdfIcon" role="img" aria-label=" (PDF)"/></a>.
* Files must not contain any copyright restrictions.


## Timing your submission

Data may be submitted and published at any time. However, if your data are associated with a journal publication, there may be special considerations:

* If you received an invitation from a journal to submit data to Dryad, then that journal has integrated its submission process with Dryad. Please follow the instructions from the journal.
* Dryad usually does not grant short- or long-term embargoes of data, but we will consider requests in specific instances (i.e., graduate students publishing thesis data that they intend to use for other parts of their thesis/dissertation; media blackouts around a study). If you wish to embargo data beyond the publication date of the associated article, we require confirmation from the publishing journal. Please submit an embargo request to <a class="emailr" href="mailto:dev@null?subject=Embargo+request&body=My+Dryad+dataset+DOI:%0D%0AEmbargo+reason:">gro.dayrdatad@pleh</a> at the time of submission.
* Regardless of journal, you may choose to make your data temporarily [private for peer review](/stash/process#private-for-peer-review).


## Login

Dryad requires an [ORCID iD](https://orcid.org) for login. If you do not have an ORCID, you will have the opportunity to create a free, unique identifier for yourself at the login page. Dryad uses ORCID so that we can authenticate and identify each individual researcher regardless of your route of entry to Dryad (i.e. through the website, through the API, through a journal integration, etc.). When datasets are published, they should appear in your ORCID profile along with articles and other works.

For institutional members, we require a second form of authentication at login. After you have logged in with your institutional credentials, Dryad ties together your ORCID and institutional affiliation so that you will not have to include this information a second time. Properly verifying your institutional affiliation is essential for recognition of institutional sponsorship of data publication charges.


## Create your submission

### Describe your dataset

You will first be asked to enter [required metadata](/stash/requirements) (information about your data). 

Our duplicate submission detector will scan the first four words of the dataset title and, if those words match an existing dataset linked to the same submitting author, a pop-up will appear on the final page of the submission form to warn of a potential identical submission. If there is no risk of duplication, you can bypass the warning and proceed.


### Prepare a README

You will be asked to create a documentation file describing your data files’ content and organization, which will serve as the main source of information for users of your dataset. [Your README](/stash/best_practices#describe-your-dataset-in-a-readme-file) can be created onscreen using our provided template, or if you have already created a README in markdown format, you may upload your file into the README editor. 

If you wish to provide additional documentation or README files in other formats, those can be uploaded along with your dataset files on the next screen. 


## Upload files

When you upload data files, ensure that they meet our [file requirements](#heading=h.gkxrj86pin4f), are able to be opened, do not contain sensitive information, and do not have licensing conflicts with [CC0](https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/).

Files can be uploaded from your local computer or from the cloud or remote servers via a URL. When using a URL, Google Drive links do not work, so please choose another mechanism. If using links from GitHub, link to the individual files rather than the repository as a whole. To confirm that files have uploaded successfully, check that all files have a size greater than 0 B.

Dryad is a platform for the raw data that were used to support the conclusions presented in an associated study. We have partnered with [Zenodo](https://zenodo.org/) to host software files and supplemental information uploaded to our site. Because non-data files or previously published files are not always compatible with the CC0 waiver required by Dryad, submitters will have the opportunity to choose a separate license for files uploaded as “Software” at the final stage of the submission process. All files uploaded as "Supplemental information" will be licensed under [CC BY](https://creativecommons.org/licenses/by/4.0/).


<img src="/images/dryad_upload.png" alt="Screenshot of file upload options" />


The "Data" category should include your primary, underlying data that has not been processed for use. Common file types include `.csv, .xlsx, .txt` and compressed file archives: `TAR.GZ, 7Z, ZIP`.

The "Software" category is reserved for code packages (R files, Python scripts, etc.) that outline all steps in processing and analyzing your data, ensuring reproducibility.

"Supplemental information" can include figures, supporting tables, appendices, etc. related to your research article. Please do not upload supplementary material that will appear on the journal’s website alongside the published article. 


### Tabular data check

For all data files uploaded to Dryad in CSV, XLS, XLSX, and TSV formats (5MB or less), a report will be automatically generated by our tabular data checker, an integration with the [Frictionless framework](https://frictionlessdata.io/). This integration allows for automated data validation, focused on the format and structure of tabular data files, prior to our curation services. JSON and XML files are also checked for basic file validity.

If any potential inconsistencies are identified, instructions will appear on the "Upload files" page, and a link to a detailed report will be provided for each affected file in the "Tabular data check" column. The report will guide you in locating and evaluating inconsistencies in your tabular data. Any files flagged in the report can be removed, edited, and reuploaded prior to proceeding with the submission process.

You can choose to proceed to the final page of the submission form without editing any files. During curation, if there are questions about how your data are presented, a curator will contact you with options to improve the organization, readability, and/or reusability of your dataset.

If you have questions, please see our [guide to the tabular data check alerts](/stash/data_check_guide). If you require assistance, [contact support](/stash/contact).


## Review and submit

On the final page of the submission form, you’ll have the opportunity to review that your metadata is correct.

Check the required acknowledgments to agree to payment of the data publication charge. If you are affiliated with a member institution or your related publication is associated with a sponsoring journal title, the option to select the acknowledgment will not be available, and a statement below will appear to confirm who is sponsoring the data publication charge. If your submission should be sponsored, but you do not see a statement indicating as much, please [contact support](/stash/contact). 


### Private for peer review

On the final page of the submission process, we offer the option to make the dataset private during your related manuscript’s peer review process. After selecting this option, you will be presented with a private URL that allows for a double-blind download of the dataset. This link can be used by the journal office or reviewers to access the data files during the review period. This temporary sharing URL is not a permanent identifier like a DOI and should be substituted with the dataset DOI at the point of final manuscript submission or the page proofs stage. The DOI reserved for your dataset will not change at any point after the dataset has been created.

When your manuscript has been accepted, you can take your dataset out of private for peer review, so that the Dryad team can begin the curation and publication processes. To do this, log in to Dryad and navigate to "My datasets". Find the submission under the "Kept private" heading. On the right, click the "Release for curation" button, and confirm.

Note that if your manuscript is submitted to, and accepted by, an integrated title that sends us status updates on your manuscript, the private for peer review period will automatically end.

If you have questions or require assistance, [contact support](/stash/contact).
