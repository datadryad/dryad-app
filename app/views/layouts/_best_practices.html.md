<h1>Good Data Practices</h1>

<h2>Best practices for creating reusable data publications</h2>

<p>So, you want to share your research data in Dryad, but are unsure where to start or what you 'should' share? Don't worry, it's not always clear how to craft a dataset with reusability in mind.</p>

<p>We want to help you share your research with the scientific community to increase its <a href="https://peerj.com/articles/175/">visibility</a> and foster collaborations. The following guidelines will help make your Dryad datasets as <a href="https://www.force11.org/group/fairgroup/fairprinciples">Findable, Accessible, Interoperable, and Reusable (FAIR)</a> as possible.</p>

<p>No time to dig into the details? Check out our <a href="/docs/QuickstartGuideToDataSharing.pdf">quickstart guide to data sharing</a>.</p>

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



<h2 id="gather">Gather all relevant data needed for reanalysis</h2>

<ul>
  <li>
    <strong>Consider all of the information necessary for one to reuse your dataset and replicate the analyses in
    your publication</strong>. Gather and organize everything&mdash;this may include experimental method details, raw data files,
    organized data tables, scripts, data visualizations, and statistical output. There are often several levels of data
    processing involved in a project, and it is important to provide adequate detail. That said, don't hesitate to edit
    out superfluous or ambiguous content that would confuse others.<br/><br/>
    Additionally, if applicable, please do not include any data visualizations that will appear in the published
    article. For example, data figures and/or other supplementary material already present within the manuscript.<br/><br/>
  </li>
  <li>
    <strong>Unprocessed and processed data:</strong> Providing both unprocessed and processed data can be valuable for
    re-analysis, assuming the data are of a reasonable size. Including unprocessed raw digital data from a recording
    instrument or database ensures that no details are lost, and any issues in the processing pipeline can be discovered
    and rectified. Processed data are cleaned, formatted, organized and ready for reuse by others.<br/><br/>
  </li>
  <li>
    <strong>Code:</strong> Programming scripts communicate to others all of the steps in processing and analysis.
    Including them ensures that your results are reproducible by others. Informative comments throughout your code will
    help future users understand its logic.<br/><br/>
  </li>
  <li>
    <strong>External resources:</strong> Links to associated data stored in other data repositories, code in
    software repositories, and associated publications can be included in "Related works".
  </li>
</ul>


<h2>Make sure your data are shareable<a name="shareable"></a></h2>

<ul>
<li><strong>All files submitted to Dryad must abide by the terms of the <a href="https://creativecommons.org/publicdomain/zero/1.0/">Creative Commons Zero (CC0 1.0)</a> waiver</strong>. Under these terms, the author releases the data to the public domain.
<ul><li>Review all files and ensure they conform to <code>CC0</code> terms and are not covered by copyright claims or other terms-of-use. We cannot archive any files that contain licenses incompatible with <code>CC0</code> (<code>GNU GPL, MIT, CC-BY,</code> etc.), but we can link to content in a dedicated software repository (Github, Zenodo, Bitbucket, or CRAN, etc.). </li>
<li>For more information see <a href="https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/">why Dryad uses <code>CC0</code></a>, and <a href="https://blog.datadryad.org/2017/09/11/some-dos-and-donts-for-cc0/">some dos and don'ts for <code>CC0</code></a>.</li></ul></li>
<li>Human subjects data must be properly anonymized and prepared under applicable legal and ethical guidelines (see tips for <a href="/docs/HumanSubjectsData.pdf">human subjects data</a>).</li>
<li>If you work with vulnerable or endangered species, it may be necessary to mask location to prevent any further threat to the population. Please review our recommendations for responsibly sharing data collected from vulnerable species (see tips for <a href="/docs/EndangeredSpeciesData.pdf">endangered species data</a>).</li>
</ul>




<h2>Make sure your data are accessible<a name="accessible"></a></h2>

<ul>
<li>To maximize accessibility, reusability and preservability, share data in non-proprietary <a href="https://en.wikipedia.org/wiki/Open_format">open formats</a> when possible (see <a href="#formats">preferred formats</a>). This ensures your data will be accessible by most people.</li>
<li>Review files for errors. Common errors include missing data, misnamed files, mislabeled variables, incorrectly formatted values, and corrupted file archives. It may be helpful to run data validation tools before sharing. For example, if you are working with tabular datasets, a service like <a href="https://goodtables.io/">goodTables</a> can identify missing data and data type formatting problems.</li>
<li>Files compression may be necessary to reduce large file sizes or directories of files. Files can be bundled together in compressed file archives (<code>.zip, .7z, .tar.gz</code>). If you have a large directory of files, and there is a logical way to split it into subdirectories and compress those, we encourage you to do so. We recommend not exceeding 10GB each.</li>
</ul>


<h2>Preferred file formats<a name="formats"></a></h2>

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


<h2 id="organize">Organize files in a logical schema</h2>

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


<img src="/images/dataset-structure.png" alt="Dataset organization">



<h2 id="describe">Describe your dataset in a README file</h2>

<p>Provide a clear and concise description of all relevant details about data collection, processing, and analysis in a README document. This will help others interpret and reanalyze your dataset.</p>

<p>Plain text README files are recommended, however, PDF is acceptable when formatting is important.</p>

<p>
  If you include a README in a compressed archive of files, please also upload it externally in the README section
  so that users are aware of the contents before downloading.
</p>

<p>Cornell University's Research Data Management Service Group has created an excellent <a href="https://data.research.cornell.edu/content/readme">README template</a></p>

<h3>Details to include:</h3>

<ul>
<li>Citation(s) of your published research derived from these data</li>
<li>Citation(s) of associated datasets stored elsewhere (include URLs)</li>
<li>Project name and executive summary</li>
<li>Contact information regarding analyses</li>
<li>Methods of data processing and analysis</li>
<li>Describe details that may influence reuse or replication efforts</li>
<li>De-identification procedures for sensitive human subjects or endangered species data</li>
<li>Specialized software (include version and developer's web address) used for analyses and file compression. If proprietary, include open source alternatives</li>
<li>Description of file(s):
<ul><li>file/directory structure</li>
<li>type(s) of data included (categorical, time-series, human subjects, etc.)</li>
<li>relationship to the tables, figures, or sections within associated publication</li>
<li>key of definitions of variable names, column headings and row labels, data codes (including missing data), and measurement units</li></ul></li>
</ul>

<p>
  Ready to get started? <a href="/stash/sessions/choose_login">Log in</a> and go to the "My Datasets" to begin your data
  submission now!
</p>


<h2 id="examples">Examples of good reusability practices</h2>

<ul>
<li>Gallo T, Fidino M, Lehrer E, Magle S (2017) Data from: Mammal diversity and metacommunity dynamics in urban green spaces: implications for urban wildlife conservation. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.9mf02">https://doi.org/10.5061/dryad.9mf02</a></li>
<li>Rajon E, Desouhant E, Chevalier M, Débias F, Menu F (2014) Data from: The evolution of bet hedging in response to local ecological conditions. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.g7jq6">https://doi.org/10.5061/dryad.g7jq6</a></li>
<li>Drake JM, Kaul RB, Alexander LW, O'Regan SM, Kramer AM, Pulliam JT, Ferrari MJ, Park AW (2015) Data from: Ebola cases and health system demand in Liberia. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.17m5q">https://doi.org/10.5061/dryad.17m5q</a></li>
<li>Wall CB, Mason RAB, Ellis WR, Cunning R, Gates RD (2017) Data from: Elevated pCO2 affects tissue biomass composition, but not calcification, in a reef coral under two light regimes. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.5vg70.3">https://doi.org/10.5061/dryad.5vg70.3</a></li>
<li>Kriebel R, Khabbazian M, Sytsma KJ (2017) Data from: A continuous morphological approach to study the evolution of pollen in a phylogenetic context: an example with the order Myrtales. Dryad Digital Repository. <a href="https://doi.org/10.5061/dryad.j17pm.2">https://doi.org/10.5061/dryad.j17pm.2</a></li>
</ul>


<h2 id="resources">Further resources</h2>

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
