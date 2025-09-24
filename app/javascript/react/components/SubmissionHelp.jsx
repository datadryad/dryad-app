/* eslint-disable max-len */
import React from 'react';
import {ExitIcon} from './ExitButton';

export default function SubmissionHelp({type}) {
  return (
    <>
      <p>An average submission follows this process:</p>
      <ol id="infographic">
        <li>
          <h3><i className="fas fa-arrow-up-from-bracket" aria-hidden="true" />Initial submission</h3>
          <p>{type === 'dataset' && 'Upload your data, complete metadata fields, and prepare a README file. '}Complete the checklist and carefully review the {type} before you {type === 'dataset' && 'pay and '}submit.</p>
        </li>
        <li>
          <h3><i className="fas fa-eye-slash" aria-hidden="true" />Private for Peer Review option</h3>
          <p>If your {type} is associated with a manuscript under review, you can choose to keep the {type} private and use a temporary sharing link for peer review. The {type} can proceed to curation once the manuscript has been accepted.</p>
        </li>
        <li>
          <h3><i className="fas fa-layer-group" aria-hidden="true" />Curation</h3>
          <p>Our experienced data curators will thoroughly evaluate each {type} to ensure the completeness of metadata{type === 'dataset' && ', documentation, and files,'} following <a href="https://www.go-fair.org/fair-principles/" target="_blank" rel="noreferrer">FAIR principles<ExitIcon /></a>.</p>
        </li>
        <li>
          <h3><i className="fas fa-arrow-rotate-left" aria-hidden="true" />Revisions</h3>
          <p>Revise your {type} based on curator feedback.<br />Don&apos;t hesitate to contact us with questions!</p>
        </li>
        <li>
          <h3><i className="fas fa-database" aria-hidden="true" />Publication</h3>
          <p>After final review, our curators will approve and publish your {type}. Your DOI will become active, and your {type} will be searchable, citable, and reusable.</p>
        </li>
      </ol>
      <p>Click the Next button to get started!</p>
    </>
  );
}

export function PublicationHelp({type}) {
  return (
    <>
      <p>If your submission is linked to an article, preprint, or manuscript, sharing that information connects your data to the work. Metadata information for your submission can be imported from some connections.</p>
      {type === 'dataset' && (
        <p>Some <a href="/journals" target="_blank">partner journals<ExitIcon /></a> will also cover the <a href="/costs" target="_blank">Data Publishing Charge<ExitIcon /></a>.</p>
      )}
    </>
  );
}

export function TitleHelp() {
  return (
    <p>A descriptive title is required for your submission. The title, author list, abstract, subjects, and funders can be imported from many preprints and published articles, or from submitted manuscripts for some <a href="/journals" target="_blank">partner journals<ExitIcon /></a>.</p>
  );
}

export function AuthHelp() {
  return (
    <>
      <p>All authors must include their name and at least one affiliation.</p>
      <p>Authors may be invited to edit this submission. One author must be the submitter. The submitter will be the point of contact for Dryad, and must approve this submission for curation and publication.</p>
      <p>An email address is required for the submitter and any other authors invited to edit the submission.</p>
      <p>Check <b>Publish email</b> to display an author&apos;s email address on the public dataset. At least one published email is required.</p>
    </>
  );
}

export function DescHelp({type}) {
  return (
    <>
      <p>An abstract is required.{type !== 'collection' && ' Briefly summarize the dataset’s structure and concepts including information regarding data values, contents of the dataset, reuse potential, and any legal or ethical considerations.'}</p>
      {type !== 'collection' && (
        <>
          <p>If this dataset is associated with an article, abstract language can be similar, but it should focus on the information relevant to the data itself, rather than to the study. See <a href="https://doi.org/10.5061/dryad.5bk4c" target="_blank" rel="noreferrer">an example of a well-composed abstract<ExitIcon /></a>.</p>
          <p>You may also add a methods section to describe how your data was collected and processed.</p>
        </>
      )}
    </>
  );
}

export function SubjHelp() {
  return (
    <>
      <p>Dryad requires one research domain (from the <a href="https://en.wikipedia.org/wiki/Fields_of_Science_and_Technology" target="_blank" rel="noreferrer">OECD Fields of Science and Technology<ExitIcon /></a>) and at least 3 subject keywords per submission.</p>
      <p>You may enter any text as a subject keyword if your desired term does not appear.</p>
    </>
  );
}

export function SuppHelp({type}) {
  return (
    <>
      <p>Adding the institutions that supported this {type === 'collection' ? 'work' : 'data'} can help connect your data with other systems and works.</p>
      {type === 'dataset' && (
        <p>Your funder may cover the Dryad <a href="/costs" target="_blank">Data Publishing Charge<ExitIcon /></a>.</p>
      )}
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
        </a> for a non-exhaustive list of direct and indirect identifiers.
      </p>
      <p>
        Data involving threatened species or sensitive habitats must also be appropriate for the public domain. See our{' '}
        <a href="/docs/EndangeredSpeciesData.pdf">
          guidance for species data<span className="pdfIcon" role="img" aria-label=" (PDF)" />
        </a> for information about masking threatened species data.
      </p>
    </>
  );
}

export function FilesHelp({date, maxFiles}) {
  return (
    <>
      <p>Files may be uploaded from your computer, or by entering a publicly accessible, individual URL for each file (for files hosted on e.g., Dropbox, OneDrive, AWS, or your lab server).</p>
      <p>{!date || new Date(date) > new Date('2025-03-12') ? `A maximum of ${maxFiles} files can be uploaded for each publication. ` : ''}Upload packaged/compressed files (.zip, .tar.gz) to retain a directory structure or reduce the size and number of your files.</p>
      <p>Dryad data is released under a <a href="https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/" target="_blank" rel="noreferrer">CC0 license waiver<ExitIcon /></a>. For your convenience, material with other license requirements can also be uploaded here, for publication at <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<ExitIcon /></a>.</p>
      <div className="callout warn">
        <p><i className="fas fa-triangle-exclamation" /> If submitting your data to a journal with double-anonymous review, be sure to remove author names and any other identifying information from your data files and README. Reviewers will have access to all files during the journal&apos;s peer review process.</p>
      </div>
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
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.nzs7h44xg#readme" target="_blank" rel="noreferrer"><ExitIcon />Genomic data
          </a> including descriptions of data of several file types
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.rr4xgxdg6#readme" target="_blank" rel="noreferrer"><ExitIcon />MATLAB files
          </a> described in detail
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.18931zd25#readme" target="_blank" rel="noreferrer"><ExitIcon />Genomic VCF and companion scripts
          </a> described in detail
        </li>
      </ul>
      <p>For code/software</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.h70rxwdq5#readme" target="_blank" rel="noreferrer"><ExitIcon />Chromatographic and mass spectrometric analysis data
          </a> with a detailed Recommended Software section
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.jdfn2z3j3#readme" target="_blank" rel="noreferrer"><ExitIcon />Neural network deep learning code
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
      <p>After <a href="/mission#our-curation-and-publication-process" target="_blank">curation<ExitIcon /></a>, <b>Dryad submissions are made publicly available</b>. If curation should be delayed because your submission needs to be kept private while the associated manuscript undergoes peer review, choose that option on this page.</p>
      {type !== 'collection' && <p>Many <a href="/join_us#members" target="_blank" rel="noreferrer">Dryad partners<ExitIcon /></a> sponsor the cost of submitting a dataset to Dryad. If you belong to a Dryad partner institution and it is not shown here, click &quot;Add a Dryad partner institution&quot;, choose your institution, and verify your credentials.</p>}
    </>
  );
}
/* eslint-enable max-len */
