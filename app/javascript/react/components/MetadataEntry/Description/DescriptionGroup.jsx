import React, {useState, useEffect} from 'react';
import Description from './Description';
import Cedar from './Cedar';

export default function DescriptionGroup({
  resource, setResource, admin, cedar,
}) {
  const [res, setRes] = useState(resource);

  const methods = res.descriptions.find((d) => d.description_type === 'methods');
  const usage = res.descriptions.find((d) => d.description_type === 'other');
  const abstract = res.descriptions.find((d) => d.description_type === 'abstract');

  const [openMethods, setOpenMethods] = useState(!!methods?.description);
  const [showCedar, setShowCedar] = useState(!!res.cedar_json);
  const [template, setTemplate] = useState(null);

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

  useEffect(() => {
    const templ = cedar.templates.find((arr) => arr[2] === 'Human Cognitive Neuroscience Data');
    if (templ) setTemplate({id: templ[0], title: templ[2]});
  }, []);

  useEffect(() => {
    setResource(res);
    const abst = res.descriptions.find((d) => d.description_type === 'abstract')?.description;
    const {title, resource_publication, subjects} = res;
    const {publication_name} = resource_publication || {};
    const keywords = subjects.map((s) => s.subject).join(',');
    const bank = /neuro|cogniti|cereb|memory|consciousness|amnesia|psychopharma|brain|hippocampus/i;
    if (bank.test(title) || bank.test(publication_name) || bank.test(keywords) || bank.test(abst)) {
      setShowCedar(true);
    }
  }, [res]);

  return (
    <>
      <h2>Description</h2>
      <Description dcsDescription={abstract} setResource={setRes} mceLabel={abstractLabel} admin={admin} />
      {openMethods ? (
        <Description dcsDescription={methods} setResource={setRes} mceLabel={methodsLabel} admin={admin} />
      ) : (
        <p><button type="button" className="o-button__plain-text1" onClick={() => setOpenMethods(true)}>+ Add methods section</button></p>
      )}
      {usage?.description && (
        <Description dcsDescription={usage} setResource={setRes} mceLabel={usageLabel} admin={admin} />
      )}
      {showCedar && template && (
        <Cedar resource={res} setResource={setRes} editorUrl={cedar.editorUrl} templates={cedar.templates} singleTemplate={template} />
      )}
    </>
  );
}
