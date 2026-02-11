import React, {useState, useEffect} from 'react';
import axios from 'axios';
import Description from './Description';
import Cedar from './Cedar';

export default function DescriptionGroup({
  resource, setResource, curator, current,
}) {
  const [methods, setMethods] = useState(null);
  const [usage, setUsage] = useState(null);
  const [abstract, setAbstract] = useState(null);

  const [openMethods, setOpenMethods] = useState(false);
  const [showCedar, setShowCedar] = useState(false);
  const [templates, setTemplates] = useState(null);

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

  useEffect(() => {
    if (current) {
      const hasMethods = resource.descriptions.find((d) => d.description_type === 'methods');
      setMethods(hasMethods);
      setUsage(resource.descriptions.find((d) => d.description_type === 'other'));
      setAbstract(resource.descriptions.find((d) => d.description_type === 'abstract'));
      setShowCedar(!!resource.cedar_json);
      setOpenMethods(!!hasMethods?.description);
    }
  }, [current]);

  useEffect(() => {
    async function cedarCheck() {
      axios.get(`/cedar/check/${resource.id}`).then((data) => {
        setShowCedar(data.data.check);
        setTemplates(data.data.templates);
      });
    }
    if (current) cedarCheck();
  }, [current, resource.title, resource.subjects, resource.resource_publication?.publication_name,
    resource.descriptions.find((d) => d.description_type === 'abstract')?.description]);

  if (!abstract?.id) {
    return <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>;
  }

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
          {showCedar && templates && (
            <Cedar resource={resource} setResource={setResource} templates={templates} />
          )}
        </>
      )}
    </>
  );
}
