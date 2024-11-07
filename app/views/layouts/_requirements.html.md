<h1>Submission requirements</h1>

## Accepted data

Dryad accepts all research data and is intended for complete, re-usable, open research datasets. 

* Dryad does **not** accept any files with licensing terms that are incompatible with the [Creative Commons Zero waiver](http://creativecommons.org/publicdomain/zero/1.0). For more information, please see [Good data practices: Removing barriers to data reuse with CC0 licensing](https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/).
* Dryad does not accept data submissions containing personally identifiable information (PII). Any data involving human subjects must adhere to IRB regulations, obtain formal consent from participants for sharing, be properly anonymized, and be prepared in accordance with legal and ethical guidelines before being considered for publication. Please see <a href="/docs/HumanSubjectsData.pdf">additional guidance on human subjects data<span class="pdfIcon" role="img" aria-label=" (PDF)"/></a>. Additionally, due to the potential risk for indirect re-identification of research participants, Dryad does not accept transcripts from interviews, focus groups, observation studies, or images, audio, or video recordings derived from or displaying human subjects. Properly de-identified micro-level or aggregated quantitative data and summarized qualitative data derived from human participant research submissions are acceptable pending curator analysis if the requirements mentioned above are met.
* Dryad will host code, scripts, software, and/or supplemental materials. Because data files are not always compatible with the CC0 license waiver required for publication, you will have the option to upload files via Dryad for hosting on [Zenodo](https://zenodo.org), which allows public software deposits with version control for the ongoing maintenance of software packages and additional licensing options for files uploaded as 'Software' or 'Supplemental information'. All files selected for upload and hosting by Zenodo will be time-released with the publication of the Dryad dataset and remain linked and accessible through the Dryad DOI.


## Preferred file formats

Most types of files can be submitted (e.g., text, spreadsheets, video, photographs, code) including compressed archives of multiple files. Dryad welcomes the submission of *data in multiple formats* to enable various reuse scenarios. For instance, Dryad's preferred format for tabular data is CSV, however, an Excel spreadsheet may optimize reuse in some cases. Thus, Dryad accepts more than just the preservation-friendly formats listed below.

* **Text**:
    * README files should be in Markdown (`MD`)
    * Comma-separated values (`CSV`) for tabular data
    * Semi-structured plain text formats for non-tabular data (e.g., protein sequences)
    * Structured plain text (`XML, JSON`)
* **Images**: `PDF, JPEG, PNG, TIFF, SVG`
* **Audio**: `FLAC, AIFF, WAV, MP3, OGG`
* **Video**: `AVI, MPEG, MP4`
* **Compressed file archive**: `TAR.GZ, 7Z, ZIP`

<div class="callout">
<p><span style="background-color: white; border-radius: 3px; padding: 4px 4px 2px">Note:</span> RAR (Roshal ARchive) is a proprietary compression format. Because users may not have access to the necessary tools to open RAR files, we cannot accept them for publication. Please open, widely supported, and easily accessible formats like those listed above.</p>
</div>


## File size

We recommend that individual files should not exceed 10GB. This ensures files are easily accessed and downloaded by Dryad users.

There is a limit of 300GB per data publication uploaded through the web interface.


## Metadata requirements

Good metadata helps make a dataset more discoverable and reusable. The metadata should describe the data themselves, rather than the study hypotheses, results, motivations, or conclusions. A thorough description of the data file, the context in which the data were collected, the measurements that were made, and the quality of the data are all important. 

We require:

* **Journal name**: If associated with a manuscript, fields for journal name and manuscript number are required; if associated with a published or in-press article, fields for journal name and DOI are required.
* **Title**: The title should be a succinct summary of both the data and study subject or focus. A good title typically contains 8 to 10 words that adequately describe the content of the dataset.
* **Author(s)**: Name, email address, primary institutional affiliation of main researcher(s) involved in producing the data.
    * Affiliations are drawn from the [Research Organization Registry (ROR)](http://ror.org)
    * If you provide your co-authors' email addresses, when the dataset is published, they will receive a message giving them the option to add their [ORCID](http://orcid.org) to the Dryad record
* **Abstract**: Brief summary of the dataset’s structure and concepts including information regarding values, contents of the dataset, reuse potential and any legal or ethical considerations. If this dataset is associated with a study, abstract language can be similar, but it should focus on the information relevant to the data itself, rather than to the study.
* **Research domain**: Primary research domain. Domains are drawn from the <a href="https://web-archive.oecd.org/2012-06-15/138575-38235147.pdf#page=6">OECD Fields of Science and Technology<span class="pdfIcon" role="img" aria-label=" (PDF)"/></a> classification.
* **Keyword(s)**: Descriptive words that may help others discover your dataset. We require a minimum of 3 keywords for submission. Keywords can match those from your related research article or, if available, you can select from a controlled vocabulary for your discipline.

We recommend:

* **Funding Information**: Name of the funding organization that supported the creation of the resource, including applicable grant number(s). Each grant and associated award number should be input separately. Options in the drop-down menu are populated from the [Research Organization Registry (ROR)](http://ror.org).
* **Research facility**: Where the research was conducted, if different from your current affiliation (e.g., a field station). Options in the drop-down menu are populated from the [Research Organization Registry (ROR)](http://ror.org).
* **Methods**: Any methodological information that may help others to understand how the data were generated (i.e. equipment/tools/reagents used, or procedures followed).
* **Related works**: Use this field to indicate resources, other than the primary article, that are associated with the data. Examples include related datasets, preprints, etc.


## Cost

Dryad is a nonprofit organization that provides long-term access to its contents at no cost to users. We are able to provide free access to data due to financial support from members and data submitters. Dryad's Data Publishing Charges (DPCs) are designed to recover the core costs of curating and preserving data.

The base DPC per data submission is $<%=  Stash::Payments::Invoicer.data_processing_charge(identifier: StashEngine::Identifier.last) / 100 %> USD. DPCs are invoiced upon curator approval for publication, unless the submitter is based at a [member institution](/stash/join_us#members) (determined by login credentials) or an [associated journal or publisher](/stash/journals) has an agreement with Dryad to sponsor the DPC.

We are sensitive to the fact that fees for individual researchers are a burden and create inequities. To better accommodate researchers who lack funds to pay the data publication charge, for any reason, we’ve expanded our waiver policy so that any author may request one. To submit your request for consideration, complete the [Fee Waiver Application form](https://docs.google.com/forms/d/e/1FAIpQLSekWZ4Dap7TYh0nap8JmPJ1dBTGeoBl1xnLS4xGH-REfrYCTQ/viewform).

Effective June 2024, Dryad's data publication charge cannot be paid using vouchers.


### Overage fees

For submissions without a sponsor or waiver, Dryad charges excess storage fees for data totaling over 50GB. For data packages in excess of 50GB, submitters will be charged $50 for each additional 10GB, or part thereof (submissions between 50 and 60GB = $50 USD, between 60 and 70GB = $100 USD, and so on).
