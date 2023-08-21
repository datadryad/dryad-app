<h1>Good data practices</h1>

## Best practices for creating reusable data publications

So, you want to share your research data in Dryad, but are unsure where to start or what you 'should' share? Don't worry, it's not always clear how to craft a dataset with reusability in mind.

We want to help you share your research with the scientific community to increase its [visibility](https://peerj.com/articles/175/) and foster collaborations. The following guidelines will help make your Dryad datasets as [Findable, Accessible, Interoperable, and Reusable (FAIR)](https://www.force11.org/group/fairgroup/fairprinciples) as possible.

No time to dig into the details? Check out our [Quickstart guide to data sharing](https://datadryad.org/docs/QuickstartGuideToDataSharing.pdf).

## Gather all relevant data needed for reanalysis

* **Consider all of the information necessary for one to reuse your dataset and replicate the analyses in your publication**. Gather and organize everything—this may include experimental method details, raw data files, organized data tables, scripts, data visualizations, and statistical output. There are often several levels of data processing involved in a project, and it is important to provide adequate detail. That said, don't hesitate to edit out superfluous or ambiguous content that would confuse others.
Additionally, if applicable, please do not include any data visualizations that will appear in the published article, e.g., data figures and/or other supplementary material already present within the manuscript.
* **Unprocessed and processed data:** Providing both unprocessed and processed data can be valuable for re-analysis, assuming the data are of a reasonable size. Including unprocessed raw digital data from a recording instrument or database ensures that no details are lost, and any issues in the processing pipeline can be discovered and rectified. Processed data are cleaned, formatted, organized and ready for reuse by others.
* **Code:** Programming scripts communicate to others all of the steps in processing and analysis. Including them ensures that your results are reproducible by others. Informative comments throughout your code will help future users understand its logic.
* **External resources:** Links to associated data stored in other data repositories, code in software repositories, and associated publications can be included in "Related works".


## Make sure your data are shareable

* **All files submitted to Dryad must abide by the terms of the [Creative Commons Zero (CC0 1.0)](https://creativecommons.org/publicdomain/zero/1.0/) waiver**. Under these terms, the author releases the data to the public domain.
    * Review all files and ensure they conform to `CC0` terms and are not covered by copyright claims or other terms-of-use. We cannot archive any files that contain licenses incompatible with `CC0` (`GNU GPL, MIT, CC-BY,` etc.), but we can link to content in a dedicated software repository (Github, Zenodo, Bitbucket, or CRAN, etc.).
    * For more information see [Good data practices: Removing barriers to data reuse with CC0 licensing](https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/), [Why Does Dryad Use CC0](https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/), and [Some dos and don'ts for CC0](https://blog.datadryad.org/2017/09/11/some-dos-and-donts-for-cc0/).
* Human subjects data must be properly anonymized and prepared under applicable legal and ethical guidelines (see [tips for human subjects data](/docs/HumanSubjectsData.pdf)).
* If you work with vulnerable or endangered species, it may be necessary to mask location to prevent any further threat to the population. Please review our recommendations for responsibly sharing data collected from vulnerable species (see [tips for endangered species data](/docs/EndangeredSpeciesData.pdf)).


## Make sure your data are accessible

* To maximize accessibility, reusability and preservability, share data in non-proprietary [open formats](https://en.wikipedia.org/wiki/Open_format) when possible (see [preferred formats](/stash/requirements#preferred-file-formats)). This ensures your data will be accessible by most people.
* Review files for errors. Common errors include missing data, misnamed files, mislabeled variables, incorrectly formatted values, and corrupted file archives. It may be helpful to run data validation tools before sharing. For example, if you are working with tabular datasets, a tool like [Frictionless validation](https://framework.frictionlessdata.io/) can identify missing data and data type formatting problems.
* File compression may be necessary to reduce large file sizes or directories of files. Files can be bundled together in compressed file archives (`.zip, .7z, .tar.gz`). If you have a large directory of files, and there is a logical way to split it into subdirectories and compress those, we encourage you to do so. We recommend not exceeding 10GB each.


## Organize files in a logical schema

### File naming

Name files and directories in a consistent and descriptive manner. Avoid vague and ambiguous filenames. Filenames should be concise, informative, and unique (see Stanford's[ best practices for file naming](https://guides.library.stanford.edu/data-best-practices)).

Avoid blank spaces and special characters (`' '!@#$%^&"`) in filenames because they can be problematic for computers to interpret. Use a common letter case pattern because they are easily read by both machines and people:

* Kebab-case: `The-quick-brown-fox-jumps-over-the-lazy-dog.txt`
* CamelCase: `TheQuickBrownFoxJumpsOverTheLazyDog.txt`
* Snake_case: `The_quick_brown_fox_jumps_over_the_lazy_dog.txt`

Include the following information when naming files:

* Date of study
* Project name
* Type of data or analysis
* File extension (`.csv, .txt, .R, .xls, .tar.gz`, etc.)


### Examples

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

A README is a documentation file that helps others interpret and reanalyze your data. Your README should be a clear and concise description of all the components of your dataset. The Dryad submission process includes the creation of a README.

README files created or imported in Dryad are included in all downloads of your full dataset, so this information can identify and explain your dataset to users regardless of whether it is accessed through the Dryad web portal. So that your README can be interpreted both on the web and as part of a download, Dryad README files are delivered in [markdown](https://www.markdownguide.org/), a language for text formatting that is also easily legible when opened as plain text.

If you wish to create a README using your preferred markdown editor, we provide a [README template](/docs/README.md) to guide you through the creation of your file.


### Details to include:

* Summary of experimental efforts underlying this dataset
* Description of file structure and contents
* Definitions of all variables, abbreviations, missing data codes, and units
* Links to other publicly accessible locations of the data
* Other sources, if any, that the data was derived from
* Any other details that may influence reuse or replication efforts


### Details *not* to include: 

* Author names, or any other potentially identifying information, if the data is being submitted to a journal with a double-blind review process in place


Ready to get started? [Log in](/stash/sessions/choose_login) and go to the "My datasets" to begin your data submission now!


## Further reading

### Examples of good reusability practices

* Gallo T, Fidino M, Lehrer E, Magle S (2017) Data from: Mammal diversity and metacommunity dynamics in urban green spaces: implications for urban wildlife conservation. Dryad Data Platform.[ https://doi.org/10.5061/dryad.9mf02](https://doi.org/10.5061/dryad.9mf02)
* Rajon E, Desouhant E, Chevalier M, Débias F, Menu F (2014) Data from: The evolution of bet hedging in response to local ecological conditions. Dryad Data Platform.[ https://doi.org/10.5061/dryad.g7jq6](https://doi.org/10.5061/dryad.g7jq6)
* Drake JM, Kaul RB, Alexander LW, O'Regan SM, Kramer AM, Pulliam JT, Ferrari MJ, Park AW (2015) Data from: Ebola cases and health system demand in Liberia. Dryad Data Platform.[ https://doi.org/10.5061/dryad.17m5q](https://doi.org/10.5061/dryad.17m5q)
* Wall CB, Mason RAB, Ellis WR, Cunning R, Gates RD (2017) Data from: Elevated pCO2 affects tissue biomass composition, but not calcification, in a reef coral under two light regimes. Dryad Data Platform.[ https://doi.org/10.5061/dryad.5vg70.3](https://doi.org/10.5061/dryad.5vg70.3)
* Kriebel R, Khabbazian M, Sytsma KJ (2017) Data from: A continuous morphological approach to study the evolution of pollen in a phylogenetic context: an example with the order Myrtales. Dryad Data Platform.[ https://doi.org/10.5061/dryad.j17pm.2](https://doi.org/10.5061/dryad.j17pm.2)


### Additional resources

* Institutional data librarians are an outstanding resource. Check with your university library's data management services team.
* [Cornell University Research Data Management Service Group's Guide to writing "readme" style metadata](https://data.research.cornell.edu/content/readme)
* [Why Dryad uses Creative Commons Zero](https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/)
* [DataONE Primer on Data Management Best Practices](https://www.dataone.org/sites/all/documents/DataONE_BP_Primer_020212.pdf)
* [Introduction to Open Science: Why data versioning and data care practices are key for science and social science](http://blogs.lse.ac.uk/impactofsocialsciences/2015/02/09/data-versioning-open-science/)
* [Making data Findable, Accessible, Interoperable, and Reusable (FAIR)](https://www.force11.org/group/fairgroup/fairprinciples)
* [Data organization in spreadsheets](http://www.tandfonline.com/doi/full/10.1080/00031305.2017.1375989)
