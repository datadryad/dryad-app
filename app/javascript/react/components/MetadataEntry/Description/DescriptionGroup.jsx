import React from 'react';
import Description from './Description';
// import Cedar from './Cedar';

export default function DescriptionGroup({resource, setResource, admin}) {
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract');
  const methods = resource.descriptions.find((d) => d.description_type === 'methods');
  const usage = resource.descriptions.find((d) => d.description_type === 'other');

  const abstractLabel = {label: 'Abstract', required: true, describe: ''};
  const methodsLabel = {
    label: 'Methods',
    required: false,
    describe: 'How was this dataset collected? How has it been processed?',
  };
  const usageLabel = {
    label: 'Usage notes',
    required: false,
    describe: 'What programs and/or software are required to open the data files included with your submission?',
  };
  return (
    <>
      <h2>Description</h2>
      <Description dcsDescription={abstract} setResource={setResource} mceLabel={abstractLabel} admin={admin} />
      <Description dcsDescription={methods} setResource={setResource} mceLabel={methodsLabel} admin={admin} />
      {usage?.description && (
        <Description dcsDescription={usage} setResource={setResource} mceLabel={usageLabel} admin={admin} />
      )}
    </>
  );
}
