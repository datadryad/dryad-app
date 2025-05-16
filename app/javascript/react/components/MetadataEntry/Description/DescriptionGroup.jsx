import React, {useState, useEffect} from 'react';
import Description from './Description';
import Cedar from './Cedar';

export default function DescriptionGroup({
  resource, setResource, curator, cedar, step,
}) {
  const methods = resource.descriptions.find((d) => d.description_type === 'methods');
  const usage = resource.descriptions.find((d) => d.description_type === 'other');
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract');

  const [openMethods, setOpenMethods] = useState(!!methods?.description);
  const [showCedar, setShowCedar] = useState(!!resource.cedar_json);
  const [template, setTemplate] = useState(null);

  const abstractLabel = {
    label: 'Abstract',
    required: true,
    describe: <><i aria-hidden="true" />An introductory description of your dataset</>,
  };
  const methodsLabel = {
    label: 'Methods',
    required: false,
    describe: <><i aria-hidden="true" />A description of the collection and processing of the data</>,
  };
  const usageLabel = {
    label: 'Usage notes',
    required: false,
    describe: <><i aria-hidden="true" />Programs and software required to open the data files</>,
  };

  const bank = /neuro|cogniti|cereb|memory|consciousness|amnesia|psychopharma|brain|hippocampus/i;

  useEffect(() => {
    if (step === 'Description') {
      const {title, resource_publication, subjects} = resource;
      const {publication_name} = resource_publication || {};
      const keywords = subjects.map((s) => s.subject).join(',');
      setShowCedar(bank.test(title) || bank.test(publication_name) || bank.test(keywords) || bank.test(abstract?.description));
    }
  }, [step]);

  useEffect(() => {
    const {title, resource_publication, subjects} = resource;
    const {publication_name} = resource_publication || {};
    const keywords = subjects.map((s) => s.subject).join(',');
    if (bank.test(title) || bank.test(publication_name) || bank.test(keywords) || bank.test(abstract?.description)) setShowCedar(true);
  }, [resource, abstract]);

  useEffect(() => {
    const templ = cedar.templates.find((arr) => arr[2] === 'Human Cognitive Neuroscience Data');
    if (templ) setTemplate({id: templ[0], title: templ[2]});
  }, []);

  return (
    <>
      <Description dcsDescription={abstract} setResource={setResource} mceLabel={abstractLabel} curator={curator} />
      {resource.resource_type.resource_type !== 'collection' && (
        <>
          {openMethods ? (
            <>
              <br />
              <Description dcsDescription={methods} setResource={setResource} mceLabel={methodsLabel} curator={curator} />
            </>
          ) : (
            <p><button type="button" className="o-button__plain-text2" onClick={() => setOpenMethods(true)}>+ Add methods section</button></p>
          )}
          {usage?.description && (
            <Description dcsDescription={usage} setResource={setResource} mceLabel={usageLabel} curator={curator} />
          )}
          {showCedar && template && (
            <Cedar resource={resource} setResource={setResource} editorUrl={cedar.editorUrl} templates={cedar.templates} singleTemplate={template} />
          )}
        </>
      )}
    </>
  );
}
