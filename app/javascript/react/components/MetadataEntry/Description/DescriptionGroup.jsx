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

  const abstractLabel = {
    label: 'Abstract',
    required: true,
    describe: <><i />An introductory description of your dataset</>,
  };
  const methodsLabel = {
    label: 'Methods',
    required: false,
    describe: <><i />A description of the collection and processing of the data</>,
  };
  const usageLabel = {
    label: 'Usage notes',
    required: false,
    describe: <><i />Programs and software required to open the data files</>,
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
      {resource.resource_type.resource_type !== 'collection' && (
        <>
          {openMethods ? (
            <Description dcsDescription={methods} setResource={setRes} mceLabel={methodsLabel} admin={admin} />
          ) : (
            <p><button type="button" className="o-button__plain-text2" onClick={() => setOpenMethods(true)}>+ Add methods section</button></p>
          )}
          {usage?.description && (
            <Description dcsDescription={usage} setResource={setRes} mceLabel={usageLabel} admin={admin} />
          )}
          {showCedar && template && (
            <Cedar resource={res} setResource={setRes} editorUrl={cedar.editorUrl} templates={cedar.templates} singleTemplate={template} />
          )}
        </>
      )}
    </>
  );
}
