<% @page_title = 'How to reuse Dryad data' %>
<h1>How to reuse Dryad data</h1>

Dryad hosts a vast collection of [curated](/mission#our-curation-and-publication-process) datasets across a wide range of scientific disciplines. We enable researchers to share, access, and reuse high-quality data. This guide helps researchers make the most of data on Dryad.


## Understanding usage rights

All datasets on Dryad are published under the **[CC0 (Creative Commons Zero)](https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/)** Public Domain Dedication. This means:


* **No restrictions**: You can reuse, modify, share, and even redistribute the data for both commercial and non-commercial purposes without asking for permission.
* **Attribution**: While you are not legally required to provide attribution under CC0, we *strongly recommend* as a scholarly courtesy to cite any data you reuse in your work. This ensures proper credit to the data creators and supports academic integrity. Dryad provides a recommended citation for each dataset, which follows this format:  
```Author(s). Year. Dataset Title [Dataset]. Publisher. DOI: Dataset DOI.```


## Ideas for reusing Dryad data

The possibilities for reusing data are vast. Here are a few key ways you can leverage the Dryad for your research:


1. **Meta-analysis:** Aggregate datasets from multiple studies to increase statistical power and provide more robust conclusions. This is common in fields like ecology, medicine, and environmental science.
2. **Secondary analysis:** Perform new analyses on existing datasets to answer different research questions or look for different patterns and relationships than those explored in the original study.
3. **Comparative studies:** Use datasets from different regions, species, or time periods to conduct comparative studies. For instance, you could examine climate change's effects on biodiversity across different ecosystems.
4. **Data validation:** Cross-validate your experimental results by comparing them with similar datasets available on Dryad. This can strengthen the reliability of your findings.
5. **Machine learning and AI training:** Dryad datasets are an excellent resource for training machine learning models, especially when large, labeled datasets are needed. Researchers in bioinformatics, genomics, and image recognition can utilize datasets for predictive modeling or algorithm development.
6. **Teaching and learning:** Datasets from Dryad can be valuable teaching tools in undergraduate or graduate courses. Students can use real-world data to practice statistical analysis, coding, or data visualization techniques.


## Tips for maximizing data reuse

### Explore Dryad data

**Discover data through search:** Dryad provides [a user-friendly search interface](/search) to help you locate datasets relevant to your interests, as well as [an API for programmatic access to datasets](/api), which is useful for large-scale data gathering, integration with software tools, or analyses that require multiple datasets. [Visit the search help page](/help/guides/search) to learn how to utilize these tools to discover relevant data.

**Combine multiple datasets for broader insights:** One of the advantages of Dryad is the availability of diverse datasets. You can combine multiple datasets to perform meta-analyses, cross-study comparisons, or integrate data from different geographical areas or species. Just ensure that data formats and variables are consistent across studies before merging.

**Explore different data formats:** Dryad datasets may come in a variety of formats (e.g., CSV, fasta, JSON). Be prepared to work with different data formats by converting them or writing scripts that can handle multiple formats. Tools like R, Python, or specialized software can be helpful for analyzing data in various formats.


### Choose the best data

**Check for updates**: Dryad allows data versioning. Published datasets can be updated or revised over time. Be sure to check back for new versions if it's been a while since you first accessed a dataset.

**Take advantage of tabular data previews**: For data in tabular formats such as TSV, CSV, and XLSX, Dryad lets you preview the contents of the file before downloading, helping you evaluate the relevance of the data for your goals.

**Check file sizes**: Data packages on Dryad can be up to 2 TB. Make sure you have the appropriate computational resources to handle and analyze the data before downloading.

**Review the metadata and README:** The README and methods information will include information about how the data was collected, any known limitations, and explanations of variables. A thorough understanding of the dataset's context will improve the accuracy and interpretation of your analyses.

**Verify data integrity and quality:** Before integrating the dataset into your research, perform data quality checks. This might include assessing missing data, identifying outliers, or confirming consistency across related variables. It ensures that the data you are using is reliable and ready for your specific analysis. 

<div class="callout">
<h4>An important note for processing Dryad data</h4>
<p>Blank cells indicate null values in the data. In addition to blank cells, Dryad recognizes the following strings as indicating a cell with no data: <code>NA</code>, <code>na</code>, <code>N/A</code>, <code>n/a</code>, <code>N.A.</code>, <code>n.a.</code>, <code>-</code>, <code>.</code>, <code>empty</code>, <code>blank</code>
<p>When processing Dryad data, note that null values may be indicated with these strings.
</div>


### Collaborate and contribute

**Collaborate with original authors**: If your work significantly expands on the dataset or involves complex questions, consider reaching out to the original authors for collaboration or clarification. Dryad provides contact information for the corresponding author on the dataset landing page.

**Create derived datasets for further research:** If your research results in new data or modifications of an existing Dryad dataset, consider sharing your derived datasets on Dryad. This can contribute to an ongoing cycle of data reuse, allowing future researchers to build upon your work and the original data.

**Engage with the Dryad community:** We offer regular educational webinars, tips, and resources for data sharing and reuse. [Visit our blog](https://blog.datadryad.org/), [subscribe to our newsletter](http://eepurl.com/hp5GxD), or follow us on social media to make sure you're getting the latest updates.
