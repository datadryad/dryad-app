<h1>Frequently asked questions</h1>

## What types of data does Dryad accept?

Dryad accepts all research data. However, this service is intended for complete, re-usable, open research datasets.</p>

Most types of files can be submitted (e.g., text, spreadsheets, video, photographs, code) including compressed archives of multiple files. View additional guidance on preservation-friendly file types.
<ul>
    <li>
        Dryad does <strong>not</strong> accept submissions that contain personally identifiable human subject information.
        Human subjects data must be properly anonymized and prepared under applicable legal and ethical guidelines. Please
        see additional guidance on <a href="https://datadryad.org/docs/HumanSubjectsData.pdf">human subjects data</a>.
    </li>
    <li>
        Dryad does <strong>not</strong> accept any files with licensing terms that are incompatible with the
        <a href="http://creativecommons.org/publicdomain/zero/1.0">Creative Commons Zero waiver</a>. For more information,
        please see <a href="https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/">Why Does Dryad Use CC0?</a>
    </li>
    <li>
      For software scripts and snapshots of software source code, files can be uploaded via Dryad and published at
      Zenodo, which allows public software deposits with version control for the ongoing maintenance of software packages.
      If you are only seeking to store code, software, and/or supplemental information please
      <a href="https://zenodo.org" target="_blank">visit Zenodo</a>.
    </li>
</ul>

## What are the size limits?

There is a limit of 300GB per data publication uploaded through the web interface. We can accept larger submissions, but the submitter needs to <a href="mailto:help@datadryad.org">contact us</a> for assistance. We recommend that individual files should not exceed 10GB. This ensures files are easily accessed and downloaded by Dryad users.

## How much does it cost?

Dryad is a nonprofit organization that provides long-term access to its contents at no cost to users. We are able to provide free access to data due to financial support from members and data submitters. Dryad's Data Publishing Charges (DPCs) are designed to recover the core costs of curating and preserving data.

Waivers are granted for submissions originating from researchers based in countries classified by the World Bank as low-income or lower-middle-income economies.

The base DPC per data submission is $<%=  Stash::Payments::Invoicer.data_processing_charge(identifier: StashEngine::Identifier.last) / 100 %> USD. DPCs are invoiced upon curator approval/publication, unless the submitter is based at a <a href="/stash/our_membership#institutional">member institution</a> (determined by login credentials), an associated journal or publisher has an agreement with Dryad to sponsor the DPC (<a href="/stash/journals">see list</a>) or the submitter is based in a fee-waiver country (see above).

### Overage fees

For submissions without a sponsor or waiver, Dryad charges excess storage fees for data totaling over 50GB. For data packages in excess of 50GB, submitters will be charged $50 for each additional 10GB, or part thereof (submissions between 50 and 60GB = $50 USD, between 60 and 70GB = $100 USD, and so on).

## How should I prepare my data files before submitting?

Assemble all data files together and create a README as a <a href="https://daringfireball.net/projects/markdown/syntax">markdown</a> text file that describes your data files, especially including how to work with files that are not a standard file format. Where possible data should be shared in an open file format, so proprietary software is not required to view or use the files.

We require:
<ul>
    <li>All files should be able to be opened without any passcode restrictions.</li>
    <li>All information needs to be in English.</li>
    <li>
        No Personal Health Information or sensitive data can be included. See tips for
        <a href="https://datadryad.org/docs/HumanSubjectsData.pdf">Human Subjects data</a> or for <a href=https://docs.gbif.org/sensitive-species-best-practices/master/en/>sensitive species</a>.
    </li>
    <li>Files must not contain any copyright restrictions.</li>
    <li>
        A <a href="https://datadryad.org/docs/README.md">README file</a> that describes your data must be included.
    </li>
</ul>

We recommend the general use of good data practices, including descriptive names for columns and rows or file names and a logical file organization. See our recommendations for <a href="/stash/best_practices">good data practices</a>.

## What should I include in my metadata?

Good metadata helps make a dataset more discoverable and reusable. The metadata should describe the data itself, rather than the study conclusions. For instance information should differ from that of an associated manuscript. A thorough description of the data file, the context in which the data were collected, the measurements that were made and the quality of the data are all important. Also see our FAQ on preparing your data.

We require:
<ul>
    <li>Journal name: If associated with a manuscript, fields for journal name and manuscript number are required.</li>
    <li>
      Title:  The title should be a succinct summary of both the data and study subject or focus. A good title
      typically contains 8 to 10 words that adequately describe the content of the dataset.
    </li>
    <li>Author(s): Name, email address, institutional affiliation of main researcher(s) involved in producing the data.</li>
    <ul>
        <li>Affiliations are drawn from the <a href="http://ror.org">Research Organization Registry (ROR)</a></li>
        <li>
            If you provide your co-authors' email addresses, when the dataset is published they will receive a message
            giving them the option to add their <a href="http://orcid.org">ORCID</a> to the Dryad record
        </li>
    </ul>
    <li>
      Abstract: Brief summary of the dataset’s structure and concepts including information regarding
      values, contents of the dataset, reuse potential and any legal or ethical considerations.
      If this dataset is associated with an article, abstract language can be similar, but it should focus
      on the information relevant to the data itself, rather than to the study.
    </li>
    <li>
      Research domain: Primary research domain. Domains are drawn from the OECD Fields of Science and Technology
      classification.
    </li>
</ul>

We recommend:
<ul>
  <li>
    Funding Information: Name of the funding organization that supported the creation of the
    resource, including applicable grant number(s). Each grant and associated award number
    should be input separately. Options in the drop-down menu are populated by the Crossref Funder Registry.
  </li>
  <li>
    Research facility: Where the research was conducted, if different from your current affiliation
    (e.g., a field station).
  </li>
  <li>
    Keyword(s): Descriptive words that may help others discover your dataset. We recommend
    that you determine whether your discipline has an existing controlled vocabulary from which to
    choose your keywords. Please enter as many keywords as applicable.
  </li>
  <li>
    Methods: Any technical or methodological information that may help others to understand
    how the data were generated (i.e. equipment/tools/reagents used, or procedures followed).
  </li>
  <li>
    Usage notes: Guidance on the programs and/or software that are required to open the data files included with your 
    submission will be helpful to include for future users of your dataset. This information will ensure ease of 
    accessibility, especially for the less common file types. If proprietary software is required, include open-source 
    alternatives.
  </li>
  <li>
    Related Works: Use this field to indicate other resources that are associated with the data.
    Examples include publications, related datasets, etc.
  </li>
</ul>

## How do I upload my files?

Files can be uploaded from your local computer or from the cloud or remote servers via a URL. Up to 300GB can be uploaded per DOI. When using a URL, Google Drive links do not work, so please choose another mechanism. If using links from GitHub, link to the individual files rather than the repository as a whole. To confirm that files have uploaded successfully, check that all files have a size greater than 0 B.

## What is the Tabular data check?

For all data files uploaded to Dryad in CSV, XLS, XLSX formats (5MB or less), a
report will be automatically generated by our tabular data checker, an
integration with the <a href="https://frictionlessdata.io/">Frictionless framework</a>. This integration allows for automated data validation, focused on the format and structure of tabular data files, prior to our curation services.

If any potential inconsistencies are identified, instructions will appear on the
"Upload files" page, and a link to a detailed report will be provided for each affected file in the
"Tabular data check" column. The report will help guide you in locating and
evaluating alerts about your tabular data. Any files flagged in the report can be removed, edited, and reuploaded prior to proceeding with the submission process.

You can choose to proceed to the final page of the submission form without editing any files. At curation stage, if there are questions about how your data is presented, a curator will contact you with options to improve the organization, readability, and/or reuse of your dataset.

"Passed" will appear in the "Tabular data check" column for any files checked without potential inconsistencies. If a file has not been checked by the validator due to size or type, the "Tabular data check" column will be blank. In any scenario, no changes will be required and you may proceed with the submission process.

If you have questions or require assistance, contact <a href="mailto:help@datadryad.org">help@datadryad.org</a>.

For more information regarding the Frictionless Data project at Open Knowledge
Foundation, visit this link: <a href="https://frictionlessdata.io/">https://frictionlessdata.io/</a>

## How does Dryad’s Private for peer review feature work?

On the final page of the submission process, we offer the option to make the dataset private during your
related manuscript’s peer review process. After selecting this option, you will be presented with a private, randomized URL that allows for a double-blind download of the dataset. This link can be used by the journal office to access the data files during the review period or shared with collaborators while the dataset is not yet published. When your manuscript has been accepted, you can take your dataset out of private for peer review, so that the Dryad team can begin the curation and publication processes. To do this, log in to Dryad and navigate to "My datasets". Find the submission with the status "Private for peer review" and click 'Update'. Deselect the "Private for peer review" checkbox on the 'Review and submit' page. At the bottom of this page, click ‘Submit'.

## When should I submit my data?

Data may be submitted and published at any time. However, if your data are associated with a journal article, there may be special considerations:
<ul>
    <li>
        Journals that are integrated with Dryad have specific requirements. Look up your journal to determine
        the proper workflow.
    </li>
    <li>
        If you received an invitation from a journal to submit data to Dryad, then that journal has integrated its
        submission process with Dryad. Please follow the instructions from the journal.
    </li>
    <li>
        If a delayed-release data embargo is allowed by your journal, you may request that
        (<a href="mailto:help@datadryad.org">help@datadryad.org</a>) at the time of submission.
    </li>
    <li>Regardless of journal, you may choose to make your data temporarily <a href="#how-does-dryad-s-private-for-peer-review-feature-work">Private for peer review</a>.</li>
</ul>

## What happens after I submit my data?

Dryad is a curated repository. We perform basic checks on each submission through <a href="#what-happens-during-curation">curation</a>. If our curators have questions or suggestions about your submission, they will contact you directly. Otherwise you will be notified when your dataset is approved.

If your data submission is <a href="#how-does-dryad-s-private-for-peer-review-feature-work">private for peer review</a> it will not be processed by our curators until the associated manuscript is accepted.

Upon curator approval, the Dryad DOI is officially registered and, if applicable, the <a href="\#how-much-does-it-cost">Data Publishing Charge (DPC)</a> and any overage fees are invoiced.

After data publication, if you have edits, additional files, or subsequent related work we recommend versioning your data by using the <a href="#how-can-i-update-my-data">&quot;update&quot;</a> link. All versions of a dataset will be accessible, but the dataset DOI will always resolve to the newest version.

## What happens during curation?

Dryad has a team of curators who check every submission to ensure the validity of files and metadata. Once your data is submitted, Dryad curators perform basic checks. As an author, you can review these for your dataset. Assuring that your dataset meets all of our requirements for metadata and data files will ensure that the curation process is as efficient and timely as possible.

<ul>
    <li><a href="#what-should-i-include-in-my-metadata">Metadata requirements</a></li>
    <li><a href="#how-should-i-prepare-my-data-files-before-submitting">File requirements</a></li>
</ul>

<p>
    If Dryad curators identify questions, problems, or areas for improvement, they will contact you directly via the
    email address associated with your submission. You may contact the curation team for questions or consultations at
    <a href="mailto:help@datadryad.org">help@datadryad.org</a>
</p>

## How do Dryad &amp; Zenodo partner and integrate?

Dryad formed a partnership with <a href="https://zenodo.org/">Zenodo</a>, a multidisciplinary repository based at CERN, in 2019. <a href="https://blog.datadryad.org/2019/07/17/funded-partnership-brings-dryad-and-zenodo-closer/">This partnership</a> leverages each organization's strengths: data curation at Dryad and software publication at Zenodo.

Through our integration, any software uploaded during the data submission process will be triaged and published at Zenodo. The software will not go through Dryad curation processes but it will be time-released with the publication of the Dryad dataset. Both the data and software packages will be linked and denoted on the Dryad landing page under “Related Works”.

Dryad stores a copy of all datasets in Zenodo for enhanced preservation services.


## How are the datasets discoverable?

All datasets will be indexed by the <a href="http://wokinfo.com/products_tools/multidisciplinary/dci/about/">Thomson-Reuters Data Citation Index</a>, <a href="http://www.elsevier.com/online-tools/scopus">Scopus</a>, and <a href="https://toolbox.google.com/datasetsearch">Google Dataset Search</a>. Each dataset is given a unique Digital Object Identifier or DOI. Entering the DOI URL in any browser will take the user to the dataset&#39;s landing page. Dryad also provides a faceted search and browse capability for direct discovery.

Dryad has implemented the <a href="https://makedatacount.org">Make Data Count</a> project
recommendations. This means that that views and downloads on each dataset landing page are standardized against the COUNTER Code of Practice for Research Data. Within this framework, Dryad also exposes all related citations to a dataset on the landing page. These are updated each time a new citation from an article or other source has been published.

Ways you can ensure your data publication has the broadest reach:
<ul>
    <li>
        <strong>Comprehensive documentation</strong> (i.e. metadata) is the key for discoverability as well as ensuring
        future researchers understand the data. Without thorough metadata (description of the context of the data file,
        the context in which the data were collected, the measurements that were made, and the quality of the data),
        the data cannot be found through internet searches or data indexing services, understood by fellow researchers,
        or effectively used. We require a few key pieces of metadata. Additional information can be included in the
        &quot;Usage notes&quot; section of the description, or as a separate readme.txt file archived alongside the
        dataset files. The metadata entry form is based on fields from the
        <a href="http://schema.datacite.org/meta/kernel-3/index.html">DataCite schema</a> and is broadly applicable
        to data from any field.
    </li>
    <li>
        <strong>Cite and publicize your data publication</strong> with your given DOI assigned upon submission. The
        recommended citation format appears on your dataset landing page.
    </li>
</ul>

## How are the datasets preserved?

<p>
    Data deposited are permanently archived and available through the <a href="http://cdlib.org/">California Digital
    Library</a>&#39;s <a href="https://merritt.cdlib.org/">Merritt Repository</a>. For a full description
    of the services provided by Merritt, see this document:
    <a href="https://merritt.cdlib.org/d/ark%3A%2F13030%2Fm52f7p63/2/producer%2FUC3-Merritt-preservation-latest.pdf">UC3,
    Merritt, and Long-term preservation</a>.
</p>

<p>Preservation policy details include:</p>

<ul>
    <li><strong>Retention period</strong>: Items will be retained indefinitely</li>
    <li>
        <strong>Functional preservation:</strong> We make no promises of usability and understandability of deposited
        objects over time.
    </li>
    <li>
        <strong>File preservation</strong>: Data files are replicated with multiple copies in multiple geographic
        locations; metadata are backed up on a nightly basis.
    </li>
    <li>
        <strong>Fixity and authenticity</strong>: All data files are stored along with a SHA-256 checksum of the
        file content. Regular checks of files against their checksums are made. The audit process cycles continually,
        with a current cycle time of approximately two months.
    </li>
    <li>
        <strong>Succession plans</strong>: In case of closure of the platform, reasonable efforts will be made to
        integrate all content into suitable alternative institutional and/or subject based repositories.
    </li>
</ul>


## How can I update my data?

You can update your data at any time by clicking on the 'Update' link for your dataset.
Any edits made will create a new version of your submission, however the DOI will remain the same. Once the latest version has been approved by our curation team and published, only the most recent version of your dataset will be packaged and available for download via the ‘Download dataset’ button. Prior versions can be accessed via the ‘Data files’ section which is organized by the date of publication.

## Can I delete my data?

Data deposited in Dryad is intended to remain permanently archived and available. Removal of a deposited dataset is considered an exceptional action which should be requested and fully justified by the original contributor (e.g., if there are concerns over privacy or data ownership). To request the withdrawal of data from Dryad, contact <a href="mailto:help@datadryad.org">help@datadryad.org</a>.

## How can I best construct my search terms when exploring data at Dryad?

<p>
    When searching in the Dryad user interface, the normal behavior is to
    treat each search term as being combined by AND. A search for <code>cat
    dog</code> will return only datasets that contain both <code>cat</code> and <code>dog</code>.
</p>

<p>
    Search terms may have a wildcard <code>*</code> appended. A search for <code>cat*</code>
    will return datasets that contain <code>cat</code>, <code>catch</code>, <code>catsup</code>, etc.
</p>

<p>
    Search terms may be negated with a minus sign. A search for <code>cat -dog</code>
    will return datasets that contain <code>cat</code>, but exclude any datasets that
    also contain <code>dog</code>.
</p>

<p>
    Phrases may be searched by using quotes. A search for <code>"dog my cats"</code>
    will only return datasets that contain this specific phrase, and not
    datasets that contain the individual terms.
</p>

<p>
    Proximity searches may be performed. To find datasets containing
    <code>dog</code> within four words of <code>cat</code>, search for <code>"dog cat"~4</code>
</p>

<p>
    Searches may also be further constrained by the filters displayed on
    the left side of the search results screen.
</p>


## Why CC0?

All data in Dryad is released into the public domain under the terms of a <a href="http://creativecommons.org/about/cc0">Creative Commons Zero</a> (CC0) waiver. CC0 was crafted specifically
to reduce any legal and technical impediments, be they intentional and unintentional, to the reuse of data. Importantly, CC0 does not exempt those who reuse the data from following community norms for scholarly communication.  It does not exempt researchers from reusing the data in a way that is mindful of its limitations.  Nor does it exempt researchers from the obligation of citing the original data authors. CC0 facilitates the discovery, re-use, and citation of that data. For more information see a post on <a href="https://blog.datadryad.org/2011/10/05/why-does-dryad-use-cc0/">Dryad’s blog</a> as well as <a href="https://osc.universityofcalifornia.edu/2016/09/cc-by-and-data-not-always-a-good-fit/">University of California’s Office of Scholarly Communications blog</a>.

## How do I cite my data?

As soon as you start a data submission a DOI is reserved for that dataset and is in the format https://doi.org/10.5061/dryad.XXXX. This, and the title and author information, is included in the Citation     section of a published dataset and the notification emails you receive from Dryad. If you need the DOI before you submit your dataset, for instance to include in a manuscript submission, you can find the DOI on the ‘Review and submit’ page under ‘Review Description’.
