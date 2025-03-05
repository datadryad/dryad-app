/* eslint-disable max-len */
import React from 'react';
import {upCase} from '../../lib/utils';

export default function SubmissionHelp({type}) {
  return (
    <>
      <p>An average submission follows this process:</p>
      <div id="infographic">
        <span id="user" className="user">{upCase(type)} authors</span>
        <span id="journal" className="journal">Journal publisher</span>
        <span id="curator" className="curator">Dryad curators</span>
        <ol>
          <li className="user" aria-describedby="user">Complete the submission checklist</li>
          <li className="user" aria-describedby="user">Review and submit the {type}</li>
          <li className="journal" aria-describedby="journal">Completes review of associated manuscript <span style={{fontSize: '.98rem'}}>(optional step)</span></li>
          <li className="curator" aria-describedby="curator">Check the {type === 'dataset' ? 'data for validity, quality, and accessibility' : 'collection metadata'}</li>
          <li className="user" aria-describedby="user">Complete any edits required from curation</li>
          <li className="curator" aria-describedby="curator">Approve and publish the {type}</li>
        </ol>
      </div>
      <p>Click the Next button to get started!</p>
    </>
  );
}

export function PublicationHelp() {
  return (
    <>
      <p>If your submission is linked to an article or manuscript, sharing that information connects your data to the work. Some <a href="/journals" target="_blank">member journals<span className="screen-reader-only"> (opens in new window)</span></a> will also cover the <a href="/requirements#cost" target="_blank">data publishing charge<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
      <p>A descriptive title is required for your submission. The title, author list, abstract, subjects, and funders can be imported from many published articles, or from submitted manuscripts for some journals.</p>
    </>
  );
}

export function AuthHelp() {
  return (
    <>
      <p>The author name and at least one affiliation are required for all authors.</p>
      <p>Authors may be invited to edit this submission. One author must be marked as the submitter, who will be the point of contact for Dryad, and must submit this for curation and publication when complete.</p>
      <p>An email address is required for the submitter and for any other authors invited to edit the submission.</p>
      <p>Check <b>Publish email</b> to display an author&apos;s email address on the public dataset. At least one published email is required.</p>
    </>
  );
}

export function SuppHelp({type}) {
  return (
    <>
      <p>Adding the institutions that supported this {type === 'collection' ? 'work' : 'data'} can aid in connections between your data and other systems and works.</p>
      <p>Your funder may cover the Dryad <a href="/requirements#cost" target="_blank">data publishing charge<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
    </>
  );
}

export function SubjHelp() {
  return (
    <p>Dryad requires one research domain (from the <a href="https://en.wikipedia.org/wiki/Fields_of_Science_and_Technology" target="_blank" rel="noreferrer">OECD Fields of Science and Technology<span className="screen-reader-only"> (opens in new window)</span></a>) and at least 3 subject keywords per submission.</p>
  );
}

export function DescHelp({type}) {
  return (
    <>
      <p>An abstract is required.{type !== 'collection' && ' Briefly summarize the dataset’s structure and concepts including information regarding data values, contents of the dataset, reuse potential and any legal or ethical considerations.'}</p>
      {type !== 'collection' && (
        <>
          <p>If this dataset is associated with an article, abstract language can be similar, but it should focus on the information relevant to the data itself, rather than to the study. See <a href="https://doi.org/10.5061/dryad.5bk4c" target="_blank" rel="noreferrer">an example of a well-composed abstract<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
          <p>You may also add a methods section to describe how your data was collected and processed.</p>
        </>
      )}
    </>
  );
}

export function FilesHelp() {
  return (
    <>
      <p>Files may be uploaded from your computer, or by entering a publically accessible, individual URL for each file (for files hosted on e.g. Box, Dropbox, AWS, or your lab server).</p>
      <p>Upload packaged/compressed files (.zip, .tar.gz) to retain a directory structure or reduce the size and number of your files.</p>
      <p>
        Any human subjects data or species data must be properly anonymized and prepared under applicable legal and ethical guidelines. Please see our{' '}
        <a href="/docs/HumanSubjectsData.pdf" target="_blank">
          human subjects guidance<span className="pdfIcon" role="img" aria-label=" (PDF)" />
          <span className="screen-reader-only"> (opens in new window)</span>
        </a> and{' '}
        <a href="/docs/EndangeredSpeciesData.pdf" target="_blank">
          species conservation guidance<span className="pdfIcon" role="img" aria-label=" (PDF)" />
          <span className="screen-reader-only"> (opens in new window)</span>
        </a>.
      </p>
      <p>Dryad data is released under a <a href="https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/" target="_blank" rel="noreferrer">CC0 license waiver<span className="screen-reader-only"> (opens in new window)</span></a>. For your convenience, material with other license requirements can also be uploaded here, for publication at <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
    </>
  );
}

export function ReadMeHelp() {
  return (
    <>
      <p>See these example READMEs from previous Dryad submissions</p>
      <p>For files and variables:</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.nzs7h44xg#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        Genomic data<span className="screen-reader-only"> (opens in new window)</span>
          </a> including descriptions of data of several file types
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.rr4xgxdg6#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        MATLAB files<span className="screen-reader-only"> (opens in new window)</span>
          </a> described in detail
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.18931zd25#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        Genomic VCF and companion scripts<span className="screen-reader-only"> (opens in new window)</span>
          </a> described in detail
        </li>
      </ul>
      <p>For code/software</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.h70rxwdq5#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
          Chromatographic and mass spectrometric analysis data<span className="screen-reader-only"> (opens in new window)</span>
          </a> with a detailed Recommended Software section
        </li>
        <li>
          <a href="https://datadryad.org/dataset/doi:10.5061/dryad.jdfn2z3j3#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        Neural network deep learning code<span className="screen-reader-only"> (opens in new window)</span>
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
      <p>After curation, <b>Dryad submissions are made publicly available unless otherwise specified</b>. If your submission needs to be kept private during the review of an associated manuscript, indicate that on this page.</p>
      {type !== 'collection' && <p>Many <a href="/join_us#members">Dryad members</a> sponsor the cost of submission to Dryad. If you belong to a Dryad member institution, make sure that is reflected here.</p>}
      <p>You may continue to edit your submission from the submission preview.</p>
    </>
  );
}
/* eslint-enable max-len */
