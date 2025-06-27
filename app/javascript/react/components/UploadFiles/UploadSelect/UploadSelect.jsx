import React from 'react';
import UploadType from './UploadType';

function UploadSelect({
  current, changed, clickedModal, resource, setResource,
}) {
  const upload_types = [
    {
      type: 'software',
      name: 'Software',
      description: 'e.g., code packages, scripts.',
      licenses: [],
    },
    {
      type: 'supp',
      name: 'Supplemental information',
      description: 'e.g., figures, supporting tables.',
      licenses: ['CC-BY'],
    },
  ];
  return (
    <div className="c-uploadwidgets">
      {upload_types.map((upload_type) => (
        <UploadType
          key={upload_type.type}
          current={current}
          changed={(e) => changed(e, upload_type.type)}
          clickedModal={() => clickedModal(upload_type.type)}
          type={upload_type.type}
          name={upload_type.name}
          description={upload_type.description}
          licenses={upload_type.licenses}
          resource={resource}
          setResource={setResource}
        />
      ))}
    </div>
  );
}

export default UploadSelect;
