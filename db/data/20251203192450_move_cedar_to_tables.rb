# frozen_string_literal: true
require 'fileutils'
require 'json'

class MoveCedarToTables < ActiveRecord::Migration[8.0]
  def up
    banks = [
      {
        label: 'Human cognitive neuroscience',
        ids: [["7479dcb2-2c2f-44c8-953d-507c8b52c06a", "Human Cognitive Neuroscience Data"]],
        kw: 'neuro|cogniti|cereb|memory|consciousness|amnesia|psychopharma|brain|hippocampus'
      },
      {
        label: 'Single-cycle fluorescence microscopy',
        ids: [
          ["745f82ce-2d70-480b-af69-b8945e5292cd", "Auto-fluorescence Dataset"],
          ["3d3c3f03-9e6e-40ba-b63a-075576cc3236", "Confocal Dataset"],
          ["87b54449-f999-4e8f-821a-e27cb77e0386", "Enhanced SRS Dataset"],
          ["5749827f-e197-4cd4-bd84-1ed9ec91dea6", "Light Sheet Dataset"],
          ["382c0eff-62ff-4884-8439-2c638b9838d1", "Second Harmonic Generation Dataset"],
          ["594b7267-01e9-4d46-b9e9-5edc52051223", "Thick Section Multiphoton MxIF Dataset"]
        ],
        kw: 'intrinsic fluoresc|endogenous fluorophore|NADH|lipofuscin|cellular autofluoresc|spectral overlap|fluorescence microscopy|tile stitching|z-stack alignment|confocal laser scanning microscopy|CLSM|optical section|PMT detector|point illumination|Z-stack|descanning|FRET|deconvolution|spinning disk|Airy disk|spectral bleed-through|stimulated Raman scatter|SRS microscopy|SRG|SRL|label-free vibrational imag|Raman spectroscopy|chemical imag|lock-in detect|frequency modulat|pump-Stokes beam|electronic pre-resonance|spectrally focused imag|LSFM|SPIM|selective plane illuminat|orthogonal illuminat|sCMOS camera|cylindrical lens|reduced photobleaching|4D imaging|galvanometric scan|Bessel beam|multi-view imag|SHG|second harmonic imag|non-linear microscopy|collagen imag|extracellular matrix|non-centrosymmetric structure|label-free imag|forward-backward detection|polarization imag|Ti:sapphire laser|myosin detect|filamentous protein|multiphoton microscopy|two-photon excitation|deep tissue imag|thick section imag|multiplex immunofluoresc|NIR excitation|Ti:sapphire laser|photobleaching reduc'
      },
      {
        label: 'Multiplexed fluorescence-based experiments',
        ids: [
          ["ff903a6b-f92e-414d-818a-d5137a03e9db", "PhenoCycler Dataset"],
          ["8c04c5b0-c34a-4e64-b1bc-be8c398a7b42", "Iterative Indirect Immunofluorescence Imaging Dataset"],
          ["fd522fce-a14d-4753-8b91-a5f3424f2614", "Cell DIVE Dataset"],
          ["e35e53ca-4653-4110-b673-d52761abfc15", "CODEX Dataset"],
          ["9775197a-b210-4350-b5c2-18e3db521a73", "COMET Dataset"],
          ["3b27c833-ae5f-4c20-b802-5851b9da1e6f", "CyCIF Dataset"]
        ],
        kw: 'multiplexed immunofluoresc|iterative stain|iterative imag|fluorophore bleach|FFPE tissue|DAPI registration|hyperplexed imag|biomarker quantification|spatial proteomics|tumor microenvironment|widefield imag|single-cell analysis|marker colocalization|co-detection by indexing|DNA-conjugated antibod|DNA barcode|oligonucleotide conjugat|fluorescent reporter|multiplex tissue imag|epitope preservation|in situ polymerization|cyclic stain|tissue architecture|cyclic immunofluoresc|fluorophore inactiv|image registration|multiplex imag|antibody cycle|DAPI counterstain|single-cell quantification|spatial analysis|tissue sections|4i|indirect immunofluorescence|antibody crosslink|multiplex protein stain|high-throughput imag|FFPE sections|subcellular resolution|off-the-shelf antibod|oxygen radical scavenger|40-plex imag|light exposure crosslink|microfluidic stain|automated sequential imag|antibody elution|image registration|hyperplex panels|spatial biology|unconjugated antibod|cyclic stain|single-use chip|closed chamber|fluorescent secondary antibod|40-marker detection|spatial transcriptomics|antibody barcod|tissue microenvironment|high-plex analysis|fluorescent tag|single-cell resolution|tissue architecture|biomarker mapping'
      },
      {
        label: 'Sequence assays',
        ids: [
          ["17653460-3b7c-4644-9351-db38360dc130", "ATACseq Dataset"],
          ["ff59e240-21de-4cf0-ab5e-a446bbfe0ec8", "MUSIC Dataset"],
          ["58b33dfd-96da-41f2-a274-9b1895da7298", "RNAseq (with probes) Dataset"],
          ["85725781-0412-40f3-8ba5-6acef6cf4120", "RNAseq Dataset"]
        ],
        kw: 'probe hybridization|targeted RNA sequenc|capture probe|gene panels|transcript detection|expression profiling|non-coding RNA|enrichment step|low-input RNA|hybrid-capture RNAseq|cDNA library preparation|ribosomal RNA depletion|gene fusions|single nucleotide variants|bulk RNAseq|single-cell RNAseq|per-cell barcoding|unique molecular identifiers|droplet emulsion PCR|reverse transcription|cDNA amplification|sequencing adapters|SNARE-seq|chromatin accessibility|sci-RNAseq|methanol fixation|fluorescence-activated cell sorting|Tn5 transposase|tagmentation|fragment file|cell barcode|insertion site|transcription start site|SAM file|BAM file|Phred score|ATACseq|SnapATAC|multinucleic acid interaction mapping|single-cell multiomics|chromatin conformation|3D genome organization|multiplex chromatin interactions|RNA-chromatin associations|single-nucleus sequenc|DNA-DNA interaction|RNA-DNA interaction|complex barcod|single-cell Hi-C|chromatin architecture|gene expression profil|multimodal sequenc'
      },
      {
        label: 'Ion mobility spectrometry',
        ids: [
          ["2544b169-9610-418f-8df7-08132a3bf47a", "DESI Dataset"],
          ["e42e077b-e94f-4909-8c5f-9b6238ac4bbb", "MALDI Dataset"],
          ["a4c38812-fba1-49f0-a1bf-28ff4e4e76fd", "SIMS Dataset"]
        ],
        kw: 'matrix-assisted laser desorption ionization|MALDI-IMS|TOF analyzer|matrix deposit|spatial distribut|UV laser|nitrogen laser|reflectron|tissue imag|peptide analysis|lipid imag|protein profil|secondary ion mass spectrometry|mass spectrometry imag|primary ion beam|dynamic SIMS|static SIMS|ToF-SIMS|NanoSIMS|depth profiling|mass-to-charge ratio|ion yield|cesium source|oxygen source|desorption electrospray ionization|ambient ionization|charged microdroplets|droplet pickup mechani|metabolite detect|lipid profil|spray geometry|3D moving stage|electrospray'
      },
      {
        label: 'Mass spectrometry',
        ids: [
          ["f24ed227-d41e-49c0-aa70-f5720a701ae7", "LC-MS Dataset"],
          ["f53e7a7e-e5e5-4eda-bc74-a8e95a338ac6", "MPLEx Dataset"]
        ],
        kw: 'liquid chromatography|mass spectrometry|electrospray ionization|reversed-phase chromatography|C18 column|acetonitrile|retention time|peptide analysis|proteomics|metabolomics|tandem MS|ion detect|molecular mass|metabolite protein lipid extract|multi-omics extract|multiomics extract|chloroform-methanol-water extraction|LC-MS|GC-MS|proteomics|metabolomics|lipidomics|single-sample preparation|reversed-phase HPLC|isobaric mass labeling|systems biology'
      },
      {
        label: 'Donor tissue sample/histiology',
        ids: [
          ["f79a1ffc-eb37-42cc-9bb5-8111757fe58b", "Sample Block"],
          ["15240463-21c8-44f2-b9d1-d1b36ab2dcf7", "Sample Section"],
          ["e51ba4cd-5b78-48f8-b240-f70e21de2f12", "Sample Suspension"],
          ["f5050476-05cf-44ab-9d85-dd7d8d755d9e", "Histology Dataset"]
        ],
        kw: 'formalin-fix|paraffin embed|tissue cassette|tissue section|sample preservation|histology block|embedding mold|microtome|specimen orientation|block face|storage archive|tissue slice|cryosection|thin section|slide mount|section thickness|staining protocol|sample integrity|cross-sectional view|optical clarity|single-cell suspension|centrifugation|resuspension buffer|cell viability|flow cytometry|dissociation protocol|cell pellet|filtration step|homogenization|staining solution|hematoxylin|eosin|cellular morphology|histopathology|slide preparation|immunohistochemistry|trichrome staining'
      }
    ]
    banks.each do |b|
      wb = CedarWordBank.create(label: b[:label], keywords: b[:kw])
      b[:ids].each do |templ|
        loc = Rails.root.join('public/cedar-embeddable-editor/templates', templ.first, 'template.json').to_s
        file = File.open(loc)
        json = JSON.load(file)
        ct = CedarTemplate.create(id: templ.first, title: templ.last, template: json, word_bank_id: wb.id)
        file.close
      end
    end
    StashEngine::Resource.where.not(old_cedar_json: ['', nil]).each do |r|
      json = JSON.parse(r.old_cedar_json)
      CedarJson.create(resource_id: r.id, template_id: json['template']['id'], json: json['metadata'], updated_at: json['updated'])
    end
  end

  def down
    CedarJson.all.each do |cj|
      cj.resource.update(old_cedar_json: JSON.generate({template: {id: cj.template_id, title: cj.cedar_template.title}, updated: cj.updated_at,metadata: cj.json}))
    end
  end
end
