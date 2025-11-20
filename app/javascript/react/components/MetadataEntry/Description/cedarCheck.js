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
  {
    bank: /4i|indirect immunofluoresc|antibody crosslink|multiplex protein stain|high-throughput imag|FFPE sections|subcellular resolution|off-the-shelf antibod|oxygen radical scaveng|40-plex imag|light exposure crosslink/i,
    name: 'Iterative Indirect Immunofluorescence Imaging Dataset',
  },
  {
    bank: /multiplexed immunofluoresc|iterative stain|fluorophore bleach|FFPE tissue|DAPI registration|hyperplexed imagi|biomarker quantification|spatial proteomics|tumor microenvironment|widefield imag|single-cell analysis|marker colocalization/i,
    name: 'Cell DIVE Dataset',
  },
  {
    bank: /co-detection by index|DNA-conjugated antibod|DNA barcode|oligonucleotide conjugation|fluorescent report|iterative imag|multiplex tissue imaging|epitope preservation|in situ polymerization|cyclic stain|tissue architecture/i,
    name: 'CODEX Dataset',
  },
  {
    bank: /microfluidic stain|automated sequential imag|antibody elution|image registration|hyperplex panel|spatial biology|unconjugated antibod|cyclic stain|single-use chip|closed chamber|fluorescent secondary antibod|40-marker detection/i,
    name: 'COMET Dataset',
  },
  {
    bank: /confocal laser scanning microscopy|CLSM|pinhole aperture|optical section|PMT detect|point illumination|Z-stack|descan|FRET|deconvolution|spinning disk|Airy disk|spectral bleed-through/i,
    name: 'Confocal Dataset',
  },
  {
    bank: /cyclic immunofluoresc|iterative stain|fluorophore inactivation|image registration|multiplex imag|antibody cycle|DAPI counterstain|segmentation|single-cell quantification|spatial analysis|fluorescence microscopy|tissue section/i,
    name: 'CyCIF Dataset',
  },
  {
    bank: /desorption electrospray ionization|ambient ionization|charged microdroplet|droplet pickup mechan|tissue imag|metabolite detection|lipid profil|spray geometry|3D moving stage|electrospray|in situ analysis/i,
    name: 'DESI Dataset',
  },
  {
    bank: /stimulated Raman scatter|SRS microscop|SRG|SRL|label-free vibrational imag|Raman spectroscop|chemical imag|lock-in detection|frequency modulation|pump-Stokes beam|electronic pre-resonance|spectrally focused imag/i,
    name: 'Enhanced SRS Dataset',
  },
  {
    bank: /LSFM|SPIM|selective plane illumination|orthogonal illumination|optical section|sCMOS camera|cylindrical lens|reduced photobleach|3D imag|4D imag|galvanometric scan|Bessel beam|multi-view imag/i,
    name: 'Light Sheet Dataset',
  },
  {
    bank: /matrix-assisted laser desorption ionization|MALDI-IMS|mass spectrometry imag| TOF analyzer|matrix deposition|spatial distribution|UV laser|nitrogen laser|reflectron|tissue imag|peptide analysis|lipid imag|protein profil/i,
    name: 'MALDI Dataset',
  },
  {
    bank: /metabolite protein lipid extraction|multi-omics extraction|chloroform-methanol-water extraction|LC-MS|GC-MS|proteomic|metabolomic|lipidomic|single-sample preparation|reversed-phase HPLC|isobaric mass label|systems biology/i,
    name: 'MPLEx Dataset',
  },
  {
    bank: /multinucleic acid interaction map|single-cell multiomics|chromatin conformation|3D genome organization|multiplex chromatin interaction|RNA-chromatin association|single-nucleus sequenc|DNA-DNA interaction|RNA-DNA interaction|complex barcod|single-cell Hi-C|chromatin architecture|gene expression profil|multimodal sequenc/i,
    name: 'MUSIC Dataset',
  },
  {
    bank: /SHG|second harmonic imag|non-linear microscopy|collagen imag|extracellular matrix|non-centrosymmetric structure|label-free imag|forward-backward detection|polarization imag|Ti:sapphire laser|myosin detection|filamentous protein/i,
    name: 'Second Harmonic Generation Dataset',
  },
  {
    bank: /secondary ion mass spectrometry|primary ion beam|dynamic SIMS|static SIMS|ToF-SIMS|NanoSIMS|depth profil|mass-to-charge ratio|ion yield|cesium source|oxygen source|chemical imag/i,
    name: 'SIMS Dataset',
  },
  {
    bank: /multiphoton microscopy|two-photon excitation|deep tissue imag|thick section imag|multiplex immunofluoresc|NIR excitation|optical section|Ti:sapphire laser|photobleaching reduction|penetration depth|fluorescence microscopy|3D imag/i,
    name: 'Thick Section Multiphoton MxIF Dataset',
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
