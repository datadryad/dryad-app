/* eslint-disable max-len */
const cedarTemplates = [
  {
    bank: /neuro|cogniti|cereb|memory|consciousness|amnesia|psychopharma|brain|hippocampus/i,
    name: 'Human Cognitive Neuroscience Data',
  },
  {
    bank: /Tn5 transposase|tagmentation|fragment file|cell barcode|insertion site|transcription start site|blacklist region|SAM file|BAM file|Phred score|ATACseq|SnapATAC/i,
    name: 'ATACseq Dataset',
  },
  {
    bank: /intrinsic fluor|endogenous fluor|NADH|lipofuscin|cellular autofluor|spectral overlap|fluorescence microscopy|tile stitching|z-stack alignment/i,
    name: 'Auto-fluorescence Dataset',
  },
  {
    bank: /tissue sectioning|hematoxylin|eosin|microscopy|cellular morphology|histopathology|slide preparation|microtome|immunohistochemistry|trichrome staining/i,
    name: 'Histology Dataset',
  },
  {
    bank: /liquid chromatography|mass spectrometry|electrospray|teversed-phase chromatography|C18 column|acetonitrile|peptide analysis|proteomics|metabolomics|tandem MS|ion detection|molecular mass/i,
    name: 'LC-MS Dataset',
  },
  {
    bank: /spatial transcriptomics|multiplex imaging|cyclic immunofluorescence|antibody barcoding|tissue microenvironment|high-plex analy|fluorescent tag|single-cell resolution|tissue architecture|biomarker mapping/i,
    name: 'PhenoCycler Dataset',
  },
  {
    bank: /probe hybrid|targeted RNA seq|capture probes|gene panels|transcript detection|expression profiling|non-coding RNA|low-input RNA|hybrid-capture RNA|cDNA library|ribosomal RNA|gene fusions|single nucleotide variant/i,
    name: 'RNAseq (with probes) Dataset',
  },
  {
    bank: /bulk RNAseq|single-cell RNAseq|per-cell barcoding|molecular identifiers|droplet emulsion PCR|reverse transcription|cDNA amplification|sequencing adapters|SNARE-seq|chromatin accessibility|sci-RNAseq|methanol fixation|fluorescence-activated cell sorting/i,
    name: 'RNAseq Dataset',
  },
  {
    bank: /formalin-fix|paraffin embed|tissue cassette|histology block|embedding mold|microtome sectioning|specimen orientation|block face|storage archive/i,
    name: 'Sample Block',
  },
  {
    bank: /tissue slice|microtome section|cryosection|thin section|slide mount|section thicknes|staining protocol|sample integrity|cross-sectional view|optical clarity/i,
    name: 'Sample Section',
  },
  {
    bank: /single-cell suspension|centrifugation|resuspension buffer|cell viability|flow cytometry|dissociation protocol|cell pellet|filtration step|homogenization|staining solution/i,
    name: 'Sample Suspension',
  },
];
/* eslint-enable max-len */

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
