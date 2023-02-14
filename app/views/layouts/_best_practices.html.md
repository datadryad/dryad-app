<h1>Good data practices</h1>

## Best practices for creating reusable data publications

<p>So, you want to share your research data in Dryad, but are unsure where to start or what you 'should' share? Don't worry, it's not always clear how to craft a dataset with reusability in mind.</p>

<p>We want to help you share your research with the scientific community to increase its <a href="https://peerj.com/articles/175/">visibility</a> and foster collaborations. The following guidelines will help make your Dryad datasets as <a href="https://www.force11.org/group/fairgroup/fairprinciples">Findable, Accessible, Interoperable, and Reusable (FAIR)</a> as possible.</p>

<p>No time to dig into the details? Check out our <a href="/docs/QuickstartGuideToDataSharing.pdf">quickstart guide to data sharing</a>.</p>

## Gather all relevant data needed for reanalysis

<ul>
  <li>
    <p><strong>Consider all of the information necessary for one to reuse your dataset and replicate the analyses in
    your publication</strong>. Gather and organize everything&mdash;this may include experimental method details, raw data files,
    organized data tables, scripts, data visualizations, and statistical output. There are often several levels of data
    processing involved in a project, and it is important to provide adequate detail. That said, don't hesitate to edit
    out superfluous or ambiguous content that would confuse others.
    <p>Additionally, if applicable, please do not include any data visualizations that will appear in the published
    article. For example, data figures and/or other supplementary material already present within the manuscript.
  </li>
  <li>
    <strong>Unprocessed and processed data:</strong> Providing both unprocessed and processed data can be valuable for
    re-analysis, assuming the data are of a reasonable size. Including unprocessed raw digital data from a recording
    instrument or database ensures that no details are lost, and any issues in the processing pipeline can be discovered
    and rectified. Processed data are cleaned, formatted, organized and ready for reuse by others.
  </li>
  <li>
    <strong>Code:</strong> Programming scripts communicate to others all of the steps in processing and analysis.
    Including them ensures that your results are reproducible by others. Informative comments throughout your code will
    help future users understand its logic.
  </li>
  <li>
    <strong>External resources:</strong> Links to associated data stored in other data repositories, code in
    software repositories, and associated publications can be included in "Related works".
  </li>
</ul>


## Make sure your data are shareable

<ul>
<li><strong>All files submitted to Dryad must abide by the terms of the <a href="https://creativecommons.org/publicdomain/zero/1.0/">Creative Commons Zero (CC0 1.0)</a> waiver</strong>. Under these terms, the author releases the data to the public domain.
<ul><li>Review all files and ensure they conform to <code>CC0</code> terms and are not covered by copyright claims or other terms-of-use. We cannot archive any files that contain licenses incompatible with <code>CC0</code> (<code>GNU GPL, MIT, CC-BY,</code> etc.), but we can link to content in a dedicated software repository (Github, Zenodo, Bitbucket, or CRAN, etc.). </li>
<li>For more information see <a href="https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/">Why Does Dryad Use <code>CC0</code></a>, and <a href="https://blog.datadryad.org/2017/09/11/some-dos-and-donts-for-cc0/">Some dos and don'ts for <code>CC0</code></a>.</li></ul></li>
<li>Human subjects data must be properly anonymized and prepared under applicable legal and ethical guidelines (see tips for <a href="/docs/HumanSubjectsData.pdf">human subjects data</a>).</li>
<li>If you work with vulnerable or endangered species, it may be necessary to mask location to prevent any further threat to the population. Please review our recommendations for responsibly sharing data collected from vulnerable species (see tips for <a href="/docs/EndangeredSpeciesData.pdf">endangered species data</a>).</li>
</ul>




## Make sure your data are accessible

<ul>
<li>To maximize accessibility, reusability and preservability, share data in non-proprietary <a href="https://en.wikipedia.org/wiki/Open_format">open formats</a> when possible (see <a href="#preferred-file-formats">preferred formats</a>). This ensures your data will be accessible by most people.</li>
<li>Review files for errors. Common errors include missing data, misnamed files, mislabeled variables, incorrectly formatted values, and corrupted file archives. It may be helpful to run data validation tools before sharing. For example, if you are working with tabular datasets, a service like <a href="https://goodtables.io/">goodTables</a> can identify missing data and data type formatting problems.</li>
<li>Files compression may be necessary to reduce large file sizes or directories of files. Files can be bundled together in compressed file archives (<code>.zip, .7z, .tar.gz</code>). If you have a large directory of files, and there is a logical way to split it into subdirectories and compress those, we encourage you to do so. We recommend not exceeding 10GB each.</li>
</ul>


## Preferred file formats

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


## Organize files in a logical schema

<h3>File naming</h3>

<p>Name files and directories in a consistent and descriptive manner. Avoid vague and ambiguous filenames. Filenames should be concise, informative, and unique (see Stanford's <a href="https://guides.library.stanford.edu/data-best-practices">best practices for file naming</a>).</p>

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
<li>File extension (<code>.csv, .txt, .R, .xls, .tar.gz</code>, etc.)</li>
</ul>

<h3>Examples</h3>
<div style="display: flex; align-items: flex-start; justify-content: flex-start; flex-wrap: wrap;">
<div style="margin-right: 4em;">
<h4 style="margin-top: 0;">A) Organized by File type</h4>
<pre>
DatasetA.tar.gz
|- Data/
|  |- Processed/
|  |- Raw/
|- Results/
|  |- Figure1.tif
|  |- Figure2.tif
|  |- Models/
|- README.md
</pre>
</div>
<div>
<h4 style="margin-top: 0;">B) Organized by Analysis</h4>
<pre>
DatasetB.tar.gz
|- Figure1/
|  |- Data/
|  |- Results
|  |  |- Figure1.tif
|- Figure2/
|  |- Data/
|  |- Results/
|  |  |- Figure2.tif
|- README.md
</pre>
</div>
</div>

## Describe your dataset in a README file

<p>Provide a clear and concise description of all components of your dataset in a README document. This will help others interpret and reanalyze your data.</p>

<p>We provide a <a href="https://datadryad.org/docs/README.md"> README template</a> in <a href="https://www.markdownguide.org/"> Markdown format</a>
  to guide you through the creation of your README documentation.</p>

<p>
  If your dataset includes compressed archives, please upload your README externally as a stand-alone file in the 'Data' category
  so that users can view its contents before downloading the full dataset.
</p>

<h3>Details to include:</h3>

<ul>
<li>Summary of experimental efforts underlying this dataset</li>
<li>Description of file structure and contents</li>
<li>Definitions of all variables, abbreviations, missing data codes, and units</li>
<li>Links to other publicly accessible locations of the data</li>
<li>Other sources, if any, that the data was derived from</li>
<li>Any other details that may influence reuse or replication efforts</li>
</ul>

<p>
  Ready to get started? <a href="/stash/sessions/choose_login">Log in</a> and go to the "My datasets" to begin your data
  submission now!
</p>


## Examples of good reusability practices

<ul>
<li>Gallo T, Fidino M, Lehrer E, Magle S (2017) Data from: Mammal diversity and metacommunity dynamics in urban green spaces: implications for urban wildlife conservation. Dryad Data Platform. <a href="https://doi.org/10.5061/dryad.9mf02">https://doi.org/10.5061/dryad.9mf02</a></li>
<li>Rajon E, Desouhant E, Chevalier M, Débias F, Menu F (2014) Data from: The evolution of bet hedging in response to local ecological conditions. Dryad Data Platform. <a href="https://doi.org/10.5061/dryad.g7jq6">https://doi.org/10.5061/dryad.g7jq6</a></li>
<li>Drake JM, Kaul RB, Alexander LW, O'Regan SM, Kramer AM, Pulliam JT, Ferrari MJ, Park AW (2015) Data from: Ebola cases and health system demand in Liberia. Dryad Data Platform. <a href="https://doi.org/10.5061/dryad.17m5q">https://doi.org/10.5061/dryad.17m5q</a></li>
<li>Wall CB, Mason RAB, Ellis WR, Cunning R, Gates RD (2017) Data from: Elevated pCO2 affects tissue biomass composition, but not calcification, in a reef coral under two light regimes. Dryad Data Platform. <a href="https://doi.org/10.5061/dryad.5vg70.3">https://doi.org/10.5061/dryad.5vg70.3</a></li>
<li>Kriebel R, Khabbazian M, Sytsma KJ (2017) Data from: A continuous morphological approach to study the evolution of pollen in a phylogenetic context: an example with the order Myrtales. Dryad Data Platform. <a href="https://doi.org/10.5061/dryad.j17pm.2">https://doi.org/10.5061/dryad.j17pm.2</a></li>
</ul>


## Further resources

<ul>
<li>Institutional data librarians are an outstanding resource. Check with your university library's data management services team.</li>
<li><a href="https://data.research.cornell.edu/content/readme">Cornell University Research Data Management Service Group's Guide to writing "readme" style metadata</a></li>
<li><a href="https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/">Why Dryad uses Creative Commons Zero</a></li>
<li><a href="https://www.dataone.org/sites/all/documents/DataONE_BP_Primer_020212.pdf">DataONE Primer on Data Management Best Practices</a></li>
<li><a href="http://blogs.lse.ac.uk/impactofsocialsciences/2015/02/09/data-versioning-open-science/">Introduction to Open Science: Why data versioning and data care practices are key for science and social science</a></li>
<li><a href="https://www.force11.org/group/fairgroup/fairprinciples">Making data Findable, Accessible, Interoperable, and Reusable (FAIR)</a></li>
<li><a href="https://try.goodtables.io/">goodTables - free online service for tabular data validation</a></li>
<li><a href="http://www.tandfonline.com/doi/full/10.1080/00031305.2017.1375989">Data organization in spreadsheets</a></li>
</ul>
