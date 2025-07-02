const cedarTemplates = [
  {
    bank: /neuro|cogniti|cereb|memory|consciousness|amnesia|psychopharma|brain|hippocampus/i,
    name: 'Human Cognitive Neuroscience Data',
  },
];

const cedarCheck = (resource, templates) => {
  const abst = resource.descriptions.find((d) => d.description_type === 'abstract')?.description;
  const {title, resource_publication, subjects} = resource;
  const {publication_name} = resource_publication || {};
  const keywords = subjects.map((s) => s.subject).join(',');
  let template = null;
  const check = cedarTemplates.some(({bank, name}) => {
    if (bank.test(title) || bank.test(publication_name) || bank.test(keywords) || bank.test(abst)) {
      template = templates.find((arr) => arr[1] === name);
      return true;
    }
    return false;
  });
  return {check, template};
};

export default cedarCheck;
