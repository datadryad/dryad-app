/* eslint-disable max-len */
import React from 'react';

export default function SubmissionHelp({type}) {
  return (
    <>
      <p>An average submission follows this process:</p>
      <div id="infographic">
        <span id="user" className="user">Dataset authors</span>
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
      <p>If your submission is associated with an article or manuscript, including that information can aid in connecting your data with that work, and some <a href="/stash/journals" target="_blank">integrated journals<span className="screen-reader-only"> (opens in new window)</span></a> cover the Dryad <a href="/stash/requirements#cost" target="_blank">data publishing charge<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
      <p>A descriptive title is required for your submission. The title, author list, and subjects can be imported from many published articles, or from submitted manuscripts for some integrated journals.</p>
    </>
  );
}

export function AuthHelp() {
  return (
    <>
      <p>Authors can be reordered.</p>
      <p><em>Information about marking corresponding authors, linking ORCIDs, and inviting editors will go here.</em></p>
    </>
  );
}

export function SuppHelp() {
  return (
    <>
      <p>Adding the institutions that supported this data can aid in connections between your data and other systems and works.</p>
      <p>Your funder may cover the Dryad <a href="/stash/requirements#cost" target="_blank">data publishing charge<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
    </>
  );
}

export function SubjHelp() {
  return (
    <p>Dryad requires one research domain (from the <a href="https://en.wikipedia.org/wiki/Fields_of_Science_and_Technology" target="_blank" rel="noreferrer">OECD Fields of Science and Technology<span className="screen-reader-only"> (opens in new window)</span></a>) and at least 3 subject keywords per submission.</p>
  );
}

export function DescHelp() {
  return (
    <p>An abstract is required. You may also add a methods section to describe how your data was collected and processed.</p>
  );
}

export function FilesHelp() {
  return (
    <>
      <p>Files may be uploaded from your computer, or by entering a publically accessible, individual URL for each file (for files hosted on e.g. Box, Dropbox, AWS, or your lab server).</p>
      <p>Upload packaged or compressed files (.zip, .tar.gz) to retain a directory structure or reduce the size and number of your files.</p>
      <p>Dryad data is released under a <a href="https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/" target="_blank" rel="noreferrer">CC0 license waiver<span className="screen-reader-only"> (opens in new window)</span></a>. For your convenience, material with other license requirements can also be uploaded here, for publication at Zenodo.</p>
    </>
  );
}

export function ReadMeHelp() {
  return (
    <>
      <p>See these example READMES from previous Dryad submissions</p>
      <p>For files and variables:</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.nzs7h44xg#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        Genomic data<span className="screen-reader-only"> (opens in new window)</span>
          </a> including descriptions of data of several file types
        </li>
        <li>
          <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.rr4xgxdg6#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        MATLAB files<span className="screen-reader-only"> (opens in new window)</span>
          </a> described in detail
        </li>
        <li>
          <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.18931zd25#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
        Genomic VCF and companion scripts<span className="screen-reader-only"> (opens in new window)</span>
          </a> described in detail
        </li>
      </ul>
      <p>For code/software</p>
      <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
        <li>
          <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.h70rxwdq5#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
          Chromatographic and mass spectrometric analysis data<span className="screen-reader-only"> (opens in new window)</span>
          </a> with a detailed Recommended Software section
        </li>
        <li>
          <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.jdfn2z3j3#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
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
      >Title/Import screen
      </span>.
    </p>
  );
}

export function AgreeHelp() {
  return (
    <>
      <p>After curation, <b>Dryad submissions are made publicly available unless otherwise specified</b>. If your submission needs to be kept private during the review of an associated manuscript, indicate that on this page.</p>
      <p>Many <a href="/join_us#members">Dryad members</a> sponsor the cost of submission to Dryad. If you belong to a Dryad member institution, make sure that is reflected here.</p>
      <p>You may continue to edit your submission from the submission preview.</p>
    </>
  );
}
/* eslint-enable max-len */
