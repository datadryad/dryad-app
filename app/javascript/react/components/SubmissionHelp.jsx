/* eslint-disable max-len */
import React from 'react';
import {ExitIcon} from './ExitButton';

export default function SubmissionHelp() {
  // need to create a version for collections
  return (
    <>
      <p>An average submission follows this process:</p>
      <ol id="infographic">
        <li>
          <h3><i className="fas fa-arrow-up-from-bracket" aria-hidden="true" />Initial submission</h3>
          <p>Upload your data, complete metadata fields, and prepare a README file. Complete the checklist and carefully review the submission before you click &quot;Submit&quot;.</p>
        </li>
        <li>
          <h3><i className="fas fa-eye-slash" aria-hidden="true" />Private for peer review option</h3>
          <p>If your dataset is associated with a manuscript under review, you can choose to keep the dataset private and use a temporary sharing link for peer review. The dataset can proceed to curation once the manuscript has been accepted.</p>
        </li>
        <li>
          <h3><i className="fas fa-layer-group" aria-hidden="true" />Curation</h3>
          <p>Our experienced data curators will thoroughly evaluate each dataset to ensure the completeness of metadata, documentation, and files, following <a href="https://www.go-fair.org/fair-principles/" target="_blank" rel="noreferrer">FAIR principles<ExitIcon/></a>.</p>
        </li>
        <li>
          <h3><i className="fas fa-arrow-rotate-left" aria-hidden="true" />Revisions</h3>
          <p>Revise your dataset based on curator feedback.<br />Don&apos;t hesitate to contact us with questions!</p>
        </li>
        <li>
          <h3><i className="fas fa-database" aria-hidden="true" />Publication</h3>
          <p>After final review, our curators will approve and publish your dataset. Your DOI will become active, and your dataset will be searchable, citable, and reusable.</p>
        </li>
      </ol>
      <p>Click the Next button to get started!</p>
    </>
  );
}

export function PublicationHelp() {
  return (
    <>
      <p>If your submission is linked to an article or manuscript, sharing that information connects your data to the work. Some <a href="/journals" target="_blank">member journals<ExitIcon/></a> will also cover the <a href="/requirements#cost" target="_blank">data publishing charge<ExitIcon/></a>.</p>
      <p>A descriptive title is required for your submission. The title, author list, abstract, subjects, and funders can be imported from many published articles, or from submitted manuscripts for some journals.</p>
    </>
  );
}

export function AuthHelp() {
  return (
    <>
      <p>All authors must include theri name and at least one affiliation.</p>
      <p>Authors may be invited to edit this submission. One author must be the submitter. The submitter will be the point of contact for Dryad, and must approve this submission for curation and publication.</p>
      <p>An email address is required for the submitter and for any other authors invited to edit the submission.</p>
      <p>Check <b>Publish email</b> to display an author&apos;s email address on the public dataset. At least one published email is required.</p>
    </>
  );
}

export function DescHelp({type}) {
  return (
    <>
      <p>An abstract is required.{type !== 'collection' && ' Briefly summarize the dataset’s structure and concepts including information regarding data values, contents of the dataset, reuse potential and any legal or ethical considerations.'}</p>
      {type !== 'collection' && (
        <>
          <p>If this dataset is associated with an article, abstract language can be similar, but it should focus on the information relevant to the data itself, rather than to the study. See <a href="https://doi.org/10.5061/dryad.5bk4c" target="_blank" rel="noreferrer">an example of a well-composed abstract<ExitIcon/></a>.</p>
          <p>You may also add a methods section to describe how your data was collected and processed.</p>
        </>
      )}
    </>
  );
}

export function SubjHelp() {
  return (
    <>
      <p>Dryad requires one research domain (from the <a href="https://en.wikipedia.org/wiki/Fields_of_Science_and_Technology" target="_blank" rel="noreferrer">OECD Fields of Science and Technology<ExitIcon/></a>) and at least 3 subject keywords per submission.</p>
      <p>You may enter any text as a subject keyword if your desired term does not appear.</p>
    </>
  );
}

export function SuppHelp({type}) {
  return (
    <>
      <p>Adding the institutions that supported this {type === 'collection' ? 'work' : 'data'} can help connect your data with other systems and works.</p>
      <p>Your funder may cover the Dryad <a href="/requirements#cost" target="_blank">data publishing charge<ExitIcon/></a>.</p>
    </>
  );
}

export function CompHelp() {
  return (
    <>
      <p>
        Dryad data is licensed as{' '}
        <a href="https://creativecommons.org/publicdomain/zero/1.0/" target="_blank" rel="noreferrer">
          Public domain
          <span role="img" aria-label="CC0 (opens in new window)" style={{marginLeft: '.25ch'}}>
            <i className="fab fa-creative-commons" aria-hidden="true" />
            <i className="fab fa-creative-commons-zero" aria-hidden="true" />
          </span>
        </a>
        . Data that comes from a source that is copyrighted cannot be published on Dryad.
        Note that data published on open-access sites or by journals does not guarantee that it is licensed under CC0.
        For example, sources may allow for data reuse but could require a citation (i.e.,{' '}
        <a href="https://creativecommons.org/licenses/by/2.0/" target="_blank" rel="noreferrer">
          Attribution
          <span role="img" aria-label="CC-BY (opens in new window)" style={{marginLeft: '.25ch'}}>
            <i className="fab fa-creative-commons" aria-hidden="true" />
            <i className="fab fa-creative-commons-by" aria-hidden="true" />
          </span>
        </a>).
      </p>
      <p>
        Any human subjects data must be properly anonymized and prepared under applicable legal and ethical guidelines.
        Dryad cannot publish any direct identifiers or more than three indirect identifiers. Please see our{' '}
        <a href="/docs/HumanSubjectsData.pdf">
          human subjects guidance<span className="pdfIcon" role="img" aria-label=" (PDF)" />
        </a> for a list of potential direct and indirect identifiers.
      </p>
      <p>
        Data involving endangered species must also be appropriate for the public domain. See our{' '}
        <a href="/docs/EndangeredSpeciesData.pdf">
          species conservation guidance<span className="pdfIcon" role="img" aria-label=" (PDF)" />
        </a> for information about masking endangered species data.
      </p>
    </>
  );
}

export function FilesHelp() {
  return (
    <>
      <p>Files may be uploaded from your computer, or by entering a publicly accessible, individual URL for each file (for files hosted on e.g. Dropbox, OneDrive, AWS, or your lab server).</p>
      <p>Upload packaged/compressed files (.zip, .tar.gz) to retain a directory structure or reduce the size and number of your files.</p>
      <p>Dryad data is released under a <a href="https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/" target="_blank" rel="noreferrer">CC0 license waiver<ExitIcon/></a>. For your convenience, material with other license requirements can also be uploaded here, for publication at <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<ExitIcon/></a>.</p>
    </>
  );
}

export function ReadMeHelp() {
  return (
    <>
      <p>See these example READMEs from published Dryad submissions</p>
      <p>For files and variables:</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.nzs7h44xg#readme" target="_blank" rel="noreferrer"><ExitIcon/>Genomic data
          </a> including descriptions of data of several file types
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.rr4xgxdg6#readme" target="_blank" rel="noreferrer"><ExitIcon/>MATLAB files
          </a> described in detail
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.18931zd25#readme" target="_blank" rel="noreferrer"><ExitIcon/>Genomic VCF and companion scripts
          </a> described in detail
        </li>
      </ul>
      <p>For code/software</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.h70rxwdq5#readme" target="_blank" rel="noreferrer"><ExitIcon/>Chromatographic and mass spectrometric analysis data
          </a> with a detailed Recommended Software section
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.jdfn2z3j3#readme" target="_blank" rel="noreferrer"><ExitIcon/>Neural network deep learning code
          </a> with excellent information on setup, access, and running the code
        </li>
      </ul>
    </>
  );
}

export function WorksHelp({setTitleStep}) {
  return (
    <p>
      The primary publication associated with your submission can be entered on the{' '}
      <span
        role="button"
        tabIndex="0"
        className="o-link__primary"
        onClick={setTitleStep}
        onKeyDown={(e) => {
          if (['Enter', 'Space'].includes(e.key)) {
            setTitleStep();
          }
        }}
      >Title screen
      </span>.
    </p>
  );
}

export function AgreeHelp({type}) {
  return (
    <>
      <p>After curation, <b>Dryad submissions are made publicly available unless otherwise specified</b>. If your submission needs to be kept private during the review of an associated manuscript, choose that option on this page.</p>
      {type !== 'collection' && <p>Many <a href="/join_us#members" target="_blank" rel="noreferrer">Dryad members<ExitIcon/></a> sponsor the cost of submitting a dataset to Dryad. If you belong to a Dryad member institution, make sure that is reflected here.</p>}
      <p>You may continue to make changes to your submission from the submission preview.</p>
    </>
  );
}
/* eslint-enable max-len */
