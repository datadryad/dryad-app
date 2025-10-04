<h1>File requirements</h1>

## Accepted data

Dryad accepts all research data and is intended for complete, re-usable, open research datasets. 

* Dryad does **not** accept any files with licensing terms that are incompatible with the [Creative Commons Zero waiver](http://creativecommons.org/publicdomain/zero/1.0). For more information, please see [Good data practices: Removing barriers to data reuse with CC0 licensing](https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/).
* Dryad does not accept data submissions containing personally identifiable information (PII). Any data involving human subjects must adhere to IRB regulations, obtain formal consent from participants for sharing, be properly anonymized, and be prepared in accordance with legal and ethical guidelines before being considered for publication. Please see <a href="/docs/HumanSubjectsData.pdf">additional guidance on human subjects data<span class="pdfIcon" role="img" aria-label=" (PDF)"/></a>. Additionally, due to the potential risk for indirect re-identification of research participants, Dryad does not accept transcripts from interviews, focus groups, observation studies, or images, audio, or video recordings derived from or displaying human subjects. Properly de-identified micro-level or aggregated quantitative data and summarized qualitative data derived from human participant research submissions are acceptable pending curator analysis if the requirements mentioned above are met.
* Dryad will host code, scripts, software, and/or supplemental materials. Because data files are not always compatible with the CC0 license waiver required for publication, you will have the option to upload files via Dryad for hosting on [Zenodo](https://zenodo.org), which allows public software deposits with version control for the ongoing maintenance of software packages and additional licensing options for files uploaded as 'Software' or 'Supplemental information'. All files selected for upload and hosting by Zenodo will be time-released with the publication of the Dryad dataset and remain linked and accessible through the Dryad DOI.


## Preferred file formats

Use CSV, TSV, or ODF formats for tabular data. Excel files (XLS or XLSX) with formatting can reduce accessibility and complicate downstream analysis. If Excel is necessary, remove any non-essential elements such as additional pages, merged cells, highlighting, embedded figures, frozen panes, comments, hyperlinks, formulas, and filters. If any of these features are essential for understanding the data, explain them clearly in the accompanying README file.

Dryad welcomes the submission of *data in multiple formats* to enable various reuse scenarios. For best practice, always submit a clean, unformatted version of the dataset in CSV, TSV, or ODF format alongside any formatted Excel files.

Most types of files can be submitted (e.g., text, spreadsheets, video, photographs, code) including compressed archives of multiple files. Preservation-friendly, open formats for files include:

* **Text**:
    * README files should be in Markdown (`MD`)
    * Comma- or tab-separated values (`CSV, TSV`) for tabular data
    * Semi-structured plain text formats for non-tabular data (e.g., protein sequences)
    * Structured plain text (`XML, JSON`)
* **Images**: `PDF, JPEG, PNG, TIFF, SVG`
* **Audio**: `FLAC, AIFF, WAV, MP3, OGG`
* **Video**: `AVI, MPEG, MP4`
* **Compressed file archive**: `TAR.GZ, 7Z, ZIP`

<div class="callout">
<p><span style="background-color: white; border-radius: 3px; padding: 4px 4px 2px">Note:</span> RAR (Roshal ARchive) is a proprietary compression format. Because users may not have access to the necessary tools to open RAR files, we cannot accept them for publication. Please use open, widely supported, and easily accessible formats like those listed above.</p>
</div>


## File size

We recommend that individual files should not exceed 10GB. This ensures files are easily accessed and downloaded by Dryad users.

There is a limit of 2 TB per data publication uploaded through the web interface.
