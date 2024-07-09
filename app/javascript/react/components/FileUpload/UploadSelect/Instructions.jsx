import React from 'react';

const instructions = () => (
  <div>
    <p>
      You may upload data via two mechanisms: directly from your computer, or from a URL
      on an external server (e.g., Box, Dropbox, AWS, lab server). We do not recommend
      using Google Drive.
    </p>
    <p>
      While you cannot upload folders directly, you can upload compressed archives (zip, tar.gz, 7z)
      in order to retain directory structure.
    </p>
    <p>
      Dryad data is released under <a href="https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/" target="_blank" rel="noreferrer">CC0</a>.
      Software and supplemental material with other license requirements
      can be uploaded for publication at <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo</a>.
      You will have the opportunity to choose a separate license for your software on the review page.
    </p>
  </div>
);

export default instructions;
