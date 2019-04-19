module DryadManuscriptSim
  TEST_DATA = { 'authors' =>
       { 'author' =>
            [{ 'familyName' => 'Mennerat',
               'givenNames' => 'Adele',
               'identifier' => nil,
               'identifierType' => nil,
               'fullName' => 'Mennerat, Adele' },
             { 'familyName' => 'Charmantier',
               'givenNames' => 'A.',
               'identifier' => nil,
               'identifierType' => nil,
               'fullName' => 'Charmantier, A.' },
             { 'familyName' => 'Jørgensen',
               'givenNames' => 'Christian',
               'identifier' => '1111-2222-1423-2355',
               'identifierType' => 'orcid',
               'fullName' => 'Jørgensen, Christian' },
             { 'familyName' => 'Eliassen',
               'givenNames' => 'Sigrunn',
               'identifier' => nil,
               'identifierType' => nil,
               'fullName' => 'Eliassen, Sigrunn' }] },
                'correspondingAuthor' =>
       { 'address' =>
            { 'addressLine1' => 'Postboks 7803',
              'addressLine2' => nil,
              'addressLine3' => nil,
              'city' => 'Bergen',
              'zip' => '5020',
              'state' => nil,
              'country' => 'Norway' },
         'author' =>
            { 'familyName' => 'Mennerat',
              'givenNames' => 'Adele',
              'identifier' => nil,
              'identifierType' => nil,
              'fullName' => 'Mennerat, Adele' },
         'email' => 'adele.mennerat@uib.no' },
                'dryadDataDOI' => '',
                'manuscriptId' => 'JAV-01701',
                'status' => 'accepted',
                'title' =>
       'Correlates of complete brood failure in blue tits: could extra-pair mating provide unexplored benefits to females?',
                'publicationDOI' => 'doi:10.1111/jav.01701',
                'publicationDate' => nil,
                'dataReviewURL' => '',
                'dataAvailabilityStatement' => '',
                'optionalProperties' =>
       { 'Journal' => 'Journal of Avian Biology', 'ISSN' => '0908-8857' },
                'keywords' => ['multiple mating', 'passerine bird', 'promiscuity'],
                'journalVolume' => '',
                'journalNumber' => '',
                'publisher' => '',
                'fullCitation' => '',
                'pages' => '',
                'taxonomicNames' => [],
                'coverageSpatial' => [],
                'coverageTemporal' => [],
                'publicationDateAsString' => '',
                'skipReviewStep' => true,
                'abstract' =>
       'Behavioural ecologists have for decades investigated the adaptive value of extra-pair copulation (EPC) for females of ' \
           'socially monogamous species. Despite extensive effort testing for genetic benefits, there now seems to be a consensus ' \
           'that the so-called ‘good genes’ effects are at most weak. In parallel the search for direct benefits has mostly focused ' \
           'on the period surrounding egg laying, thus neglecting potential correlates of EPC that might be expressed at later stages ' \
           'in the breeding cycle. Here we used Bayesian methods to analyse data collected over four years in a population of blue tits ' \
           '(Cyanistes caeruleus), where no support was previously found for ‘good genes’ effects. We found that broods with mixed ' \
           'paternity experienced less brood failure at the nestling stage than broods with single paternity, and that females ' \
           'having experienced complete brood failure in their previous breeding attempt had higher rates of mixed paternity than ' \
           'either yearling or previously successful females. To better understand these observations we also explored relationships ' \
           'between extra-pair mating, male and female phenotype, and local breeding density. We found that in almost all ' \
           'cases the sires of extra-pair offspring were close neighbours, and that within those close neighbourhoods extra-pair ' \
           'sires were older than other males not siring extra-pair offspring. Also, females did not display consistent EPC status ' \
           'across years. Taken together our results suggest that multiple mating might be a flexible female behaviour influenced by ' \
           'previous breeding experience, and motivate further experimental tests of causal links between extra-pair ' \
           'copulation and predation.' }.freeze

  def self.record
    TEST_DATA.deep_dup
  end
end
