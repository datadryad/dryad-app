import React from 'react';
import Instructions from './Instructions';
import UploadType from './UploadType';

const upload_types = [
  {
    type: 'data',
    logo: '../../../images/logo_dryad.svg',
    alt: 'Dryad',
    name: 'Data',
    description: 'e.g., csv, xsl, fasta',
    buttonFiles: 'Choose files',
    buttonURLs: 'Enter URLs',
  },
  {
    type: 'software',
    logo: '../../../images/logo_zenodo.svg',
    alt: 'Zenodo',
    name: 'Software',
    description: 'e.g., code packages, scripts',
    buttonFiles: 'Choose files',
    buttonURLs: 'Enter URLs',
  },
  {
    type: 'supp',
    logo: '../../../images/logo_zenodo.svg',
    alt: 'Zenodo',
    name: 'Supplemental information',
    description: 'e.g., figures, supporting tables',
    buttonFiles: 'Choose files',
    buttonURLs: 'Enter URLs',
  },
];

function UploadSelect({changed, clickedModal}) {
  return (
    <>
      <Instructions />
      <div className="c-uploadwidgets">
        {upload_types.map((upload_type) => (
          <UploadType
            key={upload_type.type}
            changed={(e) => changed(e, upload_type.type)}
            // triggers change to reset file uploads to null before onChange to allow files to be added again
            clickedFiles={(e) => { e.target.value = null; }}
            clickedModal={() => clickedModal(upload_type.type)}
            type={upload_type.type}
            logo={upload_type.logo}
            alt={upload_type.alt}
            name={upload_type.name}
            description={upload_type.description}
            buttonFiles={upload_type.buttonFiles}
            buttonURLs={upload_type.buttonURLs}
          />
        ))}
      </div>
    </>
  );
}

export default UploadSelect;
