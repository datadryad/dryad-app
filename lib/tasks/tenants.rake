require 'json'
# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength
namespace :tenants do

  start_tenants = [
    {
      id: 'awri',
      short_name: 'Australian Wine Research Institute',
      long_name: 'Australian Wine Research Institute',
      authentication: { strategy: 'ip_address', ranges: ['129.127.182.188', '129.127.182.166'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/0569vjj73']
    },
    {
      id: 'cdrewu',
      short_name: 'Charles R. Drew University',
      long_name: 'Charles R. Drew University of Medicine and Science',
      authentication: { strategy: 'author_match' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/038x2fh14']
    },
    {
      id: 'clare-cgu',
      short_name: 'Claremont Graduate University',
      long_name: 'Claremont Graduate University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://webauth.cgu.edu/idp/shibboleth', entity_domain: 'webauth.cgu.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/0157pnt69']
    },
    {
      id: 'clare-cmc',
      short_name: 'Claremont McKenna College',
      long_name: 'Claremont McKenna College',
      authentication: { strategy: 'shibboleth', entity_id: 'https://webauth.cmc.edu/idp/shibboleth', entity_domain: 'webauth.cmc.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/04n1me355']
    },
    {
      id: 'clare-cs',
      short_name: 'Claremont College Services (TCCS)',
      long_name: 'Claremont College Services (TCCS)',
      authentication: { strategy: 'shibboleth', entity_id: 'https://webauth.cuc.claremont.edu/idp/shibboleth',
                        entity_domain: 'webauth.cuc.claremont.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03xaz7s88',
                 'https://ror.org/0157pnt69',
                 'https://ror.org/04n1me355',
                 'https://ror.org/025ecfn45',
                 'https://ror.org/00f4jdp82',
                 'https://ror.org/0197n2v40',
                 'https://ror.org/0074grg94',
                 'https://ror.org/00p55jd14',
                 'https://ror.org/01n260e81']
    },
    {
      id: 'clare-hmc',
      short_name: 'Harvey Mudd College',
      long_name: 'Harvey Mudd College',
      authentication: { strategy: 'shibboleth', entity_id: 'https://identity.hmc.edu/idp', entity_domain: 'hmc.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/025ecfn45']
    },
    {
      id: 'clare-kgi',
      short_name: 'Keck Graduate Institute',
      long_name: 'Keck Graduate Institute',
      authentication: { strategy: 'shibboleth', entity_id: 'https://webauth.kgi.edu/idp/shibboleth', entity_domain: 'kgi.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/00f4jdp82']
    },
    {
      id: 'clare-pitzer',
      short_name: 'Pitzer College',
      long_name: 'Pitzer College',
      authentication: { strategy: 'shibboleth', entity_id: 'https://webauth.pitzer.edu/idp/shibboleth', entity_domain: 'pitzer.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/0197n2v40']
    },
    {
      id: 'clare-pomona',
      short_name: 'Pomona College',
      long_name: 'Pomona College',
      authentication: { strategy: 'shibboleth', entity_id: 'https://websso.pomona.edu/', entity_domain: 'pomona.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/0074grg94']
    },
    {
      id: 'clare-scripps',
      short_name: 'Scripps College',
      long_name: 'Scripps College',
      authentication: { strategy: 'shibboleth', entity_id: 'https://webauth.scrippscollege.edu/idp/shibboleth',
                        entity_domain: 'scrippscollege.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'clare-cs',
      ror_orgs: ['https://ror.org/00p55jd14']
    },
    {
      id: 'colostate',
      short_name: 'Colorado State University',
      long_name: 'Colorado State University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://shibidp.colostate.edu/idp/shibboleth', entity_domain: 'colostate.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03k1gpj17']
    },
    {
      id: 'columbia',
      short_name: 'Columbia University',
      long_name: 'Columbia University in the City of New York',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:columbia.edu', entity_domain: 'columbia.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['jt2118@columbia.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00hj8s172', 'https://ror.org/01esghr10']
    },
    {
      id: 'csueb',
      short_name: 'Cal State East Bay',
      long_name: 'California State University, East Bay',
      authentication: { strategy: 'shibboleth', entity_id: 'https://vince.csueastbay.edu/idp/shibboleth',
                        entity_domain: 'vince.csueastbay.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04jaeba88']
    },
    {
      id: 'dataone',
      short_name: 'DataOne',
      long_name: 'DataOne',
      authentication: { strategy: nil }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: false,
      partner_display: false,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00hr5y405']
    },
    {
      id: 'dri',
      short_name: 'Desert Research Institute',
      long_name: 'Desert Research Institute',
      authentication: { strategy: 'shibboleth', entity_id: 'http://www.okta.com/exkh1l6ocbKBRm4RB1t7', entity_domain: 'www.okta.com' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/02vg22c33']
    },
    {
      id: 'dryad',
      short_name: 'Dryad',
      long_name: 'Dryad Data Platform',
      authentication: { strategy: nil }.to_json,
      campus_contacts: Rails.env.include?('production') ? [].to_json : ['devs@datadryad.org'].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00x6h5n95']
    },
    {
      id: 'dryad_ip',
      short_name: 'Dryad IP Address Test',
      long_name: 'Dryad Data Platform IP Address Test',
      authentication: { strategy: 'ip_address', ranges: ['128.48.67.15/255.255.255.0', '127.0.0.1/255.255.255.0'] }.to_json,
      campus_contacts: Rails.env.include?('production') ? [].to_json : ['devs@datadryad.org'].to_json,
      payment_plan: nil,
      enabled: !Rails.env.include?('production'),
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: nil
    },
    {
      id: 'fws',
      short_name: 'U.S. Fish & Wildlife Service',
      long_name: 'U.S. Fish & Wildlife Service',
      authentication: { strategy: 'ip_address', ranges: ['164.159.1.1/16', '132.174.248.186'] }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['john_wenburg@fws.gov'].to_json : [].to_json,
      payment_plan: nil,
      enabled: false,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04k7dar27']
    },
    {
      id: 'iitism',
      short_name: 'Indian Institute of Technology Dhanbad',
      long_name: 'Indian Institute of Technology Dhanbad',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp.iitism.ac.in/idp/shibboleth', entity_domain: 'idp.iitism.ac.in' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: false,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/013v3cc28']
    },
    {
      id: 'kaust',
      short_name: 'King Abdullah University of Science and Technology',
      long_name: 'King Abdullah University of Science and Technology',
      authentication: { strategy: 'shibboleth', entity_id: 'https://waseet.kaust.edu.sa/idp/shibboleth',
                        entity_domain: 'waseet.kaust.edu.sa' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01q3tbs38', 'https://ror.org/02f6hdc06', 'https://ror.org/00qd31w11']
    },
    {
      id: 'kyotou',
      short_name: 'Kyoto University',
      long_name: 'Kyoto University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://authidp2.iimc.kyoto-u.ac.jp/idp/shibboleth',
                        entity_domain: 'authidp2.iimc.kyoto-u.ac.jp' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: false,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/02kpeqv85', 'https://ror.org/05gwbwn20', 'https://ror.org/05qs31q25']
    },
    {
      id: 'lbnl',
      short_name: 'Lawrence Berkeley Lab',
      long_name: 'Lawrence Berkeley National Laboratory',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:lbl.gov', entity_domain: 'datasets2-dev.lbl.gov' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/02jbv0t02']
    },
    {
      id: 'macalester',
      short_name: 'Macalester College',
      long_name: 'Macalester College',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp.macalester.edu/openathens', entity_domain: 'macalester.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04fceqm38']
    },
    {
      id: 'mit',
      short_name: 'Massachusetts Institute of Technology',
      long_name: 'Massachusetts Institute of Technology',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:mit.edu', entity_domain: 'mit.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/042nb2s44',
        'https://ror.org/032q5ym94',
        'https://ror.org/00rj4dg52',
        'https://ror.org/01t9bgr30',
        'https://ror.org/022z6jk58',
        'https://ror.org/03fg5ns40',
        'https://ror.org/053tmcn30',
        'https://ror.org/0071sjj14',
        'https://ror.org/05ymca674',
        'https://ror.org/02dgwnb72',
        'https://ror.org/053r20n13',
        'https://ror.org/04pvzz946',
        'https://ror.org/04vqm6w82'
      ]
    },
    {
      id: 'mq',
      short_name: 'Macquarie University',
      long_name: 'Macquarie University',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:federation.org.au:testfed:mq.edu.au', entity_domain: 'mq.edu.au' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['shawn.ross@mq.edu.au'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01sf06y89']
    },
    {
      id: 'msu',
      short_name: 'Montana State University',
      long_name: 'Montana State University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://login.montana.edu/idp/shibboleth', entity_domain: 'login.montana.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/02w0trx84', 'https://ror.org/04ygywa46', 'https://ror.org/0343myz07']
    },
    {
      id: 'msu2',
      short_name: 'Michigan State University',
      long_name: 'Michigan State University',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:msu.edu', entity_domain: 'msu.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/05hs6h993']
    },
    {
      id: 'ncsu',
      short_name: 'North Carolina State University',
      long_name: 'North Carolina State University',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ncsu.edu', entity_domain: 'ncsu.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['slivey@ncsu.edu', 'mcdowney@ncsu.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04tj63d06']
    },
    {
      id: 'neomed',
      short_name: 'Northeast Ohio Medical University',
      long_name: 'Northeast Ohio Medical University',
      authentication: { strategy: 'ip_address',
                        ranges: ['140.220.0.0/16', '199.18.154.122', '199.18.154.123', '199.18.157.82', '132.174.254.221'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04q9qf557']
    },
    {
      id: 'nioo-knaw',
      short_name: 'Nederlands Instituut voor Ecologie',
      long_name: 'Netherlands Institute of Ecology (NIOO-KNAW)',
      authentication: { strategy: 'shibboleth', entity_id: 'http://federation.nioo.knaw.nl/adfs/services/trust',
                        entity_domain: 'nioo.knaw.nl' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['Library@nioo.knaw.nl'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01g25jp36']
    },
    {
      id: 'nmsu',
      short_name: 'New Mexico State University',
      long_name: 'New Mexico State University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://sts.windows.net/a3ec87a8-9fb8-4158-ba8f-f11bace1ebaa/',
                        entity_domain: 'sts.windows.net' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00hpz7z43', 'https://ror.org/007sts724', 'https://ror.org/01kbvt179', 'https://ror.org/035k7dd86']
    },
    {
      id: 'northwestern',
      short_name: 'Northwestern University',
      long_name: 'Northwestern University',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:northwestern.edu', entity_domain: 'northwestern.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['chris-diaz@northwestern.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/000e0be47']
    },
    {
      id: 'nyit',
      short_name: 'New York Institute of Technology',
      long_name: 'New York Institute of Technology',
      authentication: { strategy: 'shibboleth', entity_id: 'http://www.okta.com/exkiiea33x6YYZI5k4x7', entity_domain: 'nyit.okta.com' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01bghzb51']
    },
    {
      id: 'ohiostate',
      short_name: 'Ohio State University',
      long_name: 'The Ohio State University',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:osu.edu', entity_domain: 'osu.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/00rs6vg23',
        'https://ror.org/020yh1f96',
        'https://ror.org/00c01js51',
        'https://ror.org/01r8m0a35',
        'https://ror.org/00qa31321',
        'https://ror.org/05h8s0v03',
        'https://ror.org/03646q924'
      ]
    },
    {
      id: 'ou',
      short_name: 'University of Oklahoma',
      long_name: 'University of Oklahoma',
      authentication: { strategy: 'shibboleth', entity_id: 'https://shib.ou.edu/idp/shibboleth', entity_domain: 'shib.ou.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/02aqsxs83']
    },
    {
      id: 'rochester',
      short_name: 'University of Rochester',
      long_name: 'University of Rochester',
      authentication: { strategy: 'shibboleth', entity_id: 'https://uidp-prod.its.rochester.edu/idp/shibboleth',
                        entity_domain: 'shib2.its.rochester.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['s.pugachev@rochester.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/022kthw22', 'https://ror.org/00trqv719']
    },
    {
      id: 'rockefeller',
      short_name: 'Rockefeller University',
      long_name: 'The Rockefeller University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://rushib.rockefeller.edu/idp/shibboleth',
                        entity_domain: 'rushib.rockefeller.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/0420db125', 'https://ror.org/00jjq6q61']
    },
    {
      id: 'sheffield',
      short_name: 'University of Sheffield',
      long_name: 'The University of Sheffield',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp-qa.shef.ac.uk/shibboleth', entity_domain: 'shef.ac.uk' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/05krs5044']
    },
    {
      id: 'stanford',
      short_name: 'Stanford University',
      long_name: 'Stanford University, Lane Medical Library',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:stanford.edu', entity_domain: 'stanford.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['jborghi@stanford.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/00f54p054',
        'https://ror.org/03mtd9a03',
        'https://ror.org/019wqcg20',
        'https://ror.org/05s570m15',
        'https://ror.org/05gzmn429',
        'https://ror.org/011pcwc98'
      ]
    },
    {
      id: 'suny-buffalo',
      short_name: 'SUNY Buffalo',
      long_name: 'University at Buffalo',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:buffalo.edu', entity_domain: 'buffalo.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01y64my43']
    },
    {
      id: 'suny-buffalostate',
      short_name: 'Buffalo State',
      long_name: 'SUNY Buffalo State University',
      authentication: { strategy: 'ip_address', ranges: ['136.183.0.0/16'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'suny',
      ror_orgs: ['https://ror.org/05ms04m92']
    },
    {
      id: 'suny-downstate',
      short_name: 'SUNY Downstate',
      long_name: 'SUNY Downstate Health Sciences University',
      authentication: { strategy: 'ip_address', ranges: ['138.5.0.0/16'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'suny',
      ror_orgs: ['https://ror.org/0041qmd21']
    },
    {
      id: 'suny-fredonia',
      short_name: 'SUNY Fredonia',
      long_name: 'State University of New York at Fredonia',
      authentication: { strategy: 'ip_address', ranges: ['141.238.0.0/16', '141.238.1.23/24', '132.174.249.205/24'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'suny',
      ror_orgs: ['https://ror.org/05vrs0r17']
    },
    {
      id: 'suny-geneseo',
      short_name: 'SUNY Geneseo',
      long_name: 'State University of New York College at Geneseo',
      authentication: { strategy: 'ip_address', ranges: ['137.238.0.0/16'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: 'suny',
      ror_orgs: ['https://ror.org/03g1q6c06']
    },
    {
      id: 'suny-stonybrook',
      short_name: 'SUNY Stony Brook',
      long_name: 'Stony Brook University',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:stonybrook.edu', entity_domain: 'stonybrook.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/05qghxh33']
    },
    {
      id: 'suny',
      short_name: 'State University of New York',
      long_name: 'State University of New York',
      authentication: { strategy: 'ip_address', ranges: ['192.168.100.100/31'] }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: false,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/01q1z8k08',
        'https://ror.org/008rmbt77',
        'https://ror.org/05ms04m92',
        'https://ror.org/0306aeb62',
        'https://ror.org/02n1c7856',
        'https://ror.org/057trrr89',
        'https://ror.org/02rrhsz92',
        'https://ror.org/00qv0tw17',
        'https://ror.org/05vrs0r17',
        'https://ror.org/03g1q6c06',
        'https://ror.org/02r3ym141',
        'https://ror.org/033zmj163',
        'https://ror.org/000fxgx19',
        'https://ror.org/040kfrw16',
        'https://ror.org/05a4pj207',
        'https://ror.org/02v9m6h26',
        'https://ror.org/02d4maz67',
        'https://ror.org/03j3dv688',
        'https://ror.org/01597g643',
        'https://ror.org/032qgrc76',
        'https://ror.org/05qghxh33',
        'https://ror.org/012zs8222',
        'https://ror.org/01y64my43',
        'https://ror.org/0041qmd21'
      ]
    },
    {
      id: 'sydneynsw',
      short_name: 'University of New South Wales, Sydney',
      long_name: 'University of New South Wales, Sydney',
      authentication: { strategy: 'shibboleth', entity_id: 'https://aaf.unsw.edu.au/idp/shibboleth', entity_domain: 'aaf.unsw.edu.au' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03r8z3t63']
    },
    {
      id: 'temple',
      short_name: 'Temple University',
      long_name: 'Temple University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://fim.temple.edu/idp/shibboleth', entity_domain: 'temple.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00kx1jb78', 'https://ror.org/04zzmzt85']
    },
    {
      id: 'templehealth',
      short_name: 'Temple Health',
      long_name: 'Temple University Health System',
      authentication: { strategy: nil }.to_json,
      campus_contacts: [].to_json,
      payment_plan: 0,
      enabled: true,
      partner_display: false,
      covers_dpc: true,
      sponsor_id: 'temple',
      ror_orgs: ['https://ror.org/02fhvxj45', 'https://ror.org/028rvnd71', 'https://ror.org/0567t7073', 'https://ror.org/029xz3860']
    },
    {
      id: 'ttu',
      short_name: 'Texas Tech University',
      long_name: 'Texas Tech University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp.shibboleth.ttu.edu/idp/shibboleth', entity_domain: 'ttu.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/0405mnx93']
    },
    {
      id: 'uark',
      short_name: 'University of Arkansas',
      long_name: 'University of Arkansas at Fayetteville',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp.uark.edu/idp/shibboleth', entity_domain: 'uark.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/05jbt9m15']
    },
    {
      id: 'ubc',
      short_name: 'University of British Columbia',
      long_name: 'The University of British Columbia',
      authentication: { strategy: 'shibboleth', entity_id: 'https://authentication.ubc.ca', entity_domain: 'authentication.ubc.ca' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03rmrcq20']
    },
    {
      id: 'ucb',
      short_name: 'UC Berkeley',
      long_name: 'University of California, Berkeley',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:berkeley.edu', entity_domain: '.berkeley.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['asackmann@berkeley.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/01an7q238',
        'https://ror.org/03djjyk45',
        'https://ror.org/01ewh7m12',
        'https://ror.org/03rafms67',
        'https://ror.org/05kbg7k66',
        'https://ror.org/02mmp8p21'
      ]
    },
    {
      id: 'ucd',
      short_name: 'UC Davis',
      long_name: 'University of California, Davis',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucdavis.edu', entity_domain: '.ucdavis.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['vensberg@ucdavis.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/05rrcem69',
        'https://ror.org/05q8kyc69',
        'https://ror.org/05ehe8t08',
        'https://ror.org/00fyrp007',
        'https://ror.org/05t6gpm70'
      ]
    },
    {
      id: 'uci',
      short_name: 'UC Irvine',
      long_name: 'University of California, Irvine',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:uci.edu', entity_domain: '.lib.uci.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['lsmart@uci.edu', 'kaned@uci.edu', 'wdahdul@uci.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04gyf1771', 'https://ror.org/03fgher32', 'https://ror.org/00cm8nm15', 'https://ror.org/03bfp2076']
    },
    {
      id: 'ucla',
      short_name: 'UC Los Angeles',
      long_name: 'University of California, Los Angeles',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucla.edu', entity_domain: '.ucla.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['tdennis@library.ucla.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/046rm7j60',
        'https://ror.org/05h4zj272',
        'https://ror.org/04p5baq95',
        'https://ror.org/03b66rp04',
        'https://ror.org/04k3jt835',
        'https://ror.org/01d88se56',
        'https://ror.org/04vq5kb54',
        'https://ror.org/00mjfew53'
      ]
    },
    {
      id: 'ucm',
      short_name: 'UC Merced',
      long_name: 'University of California, Merced',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucmerced.edu', entity_domain: '.ucmerced.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['elin@ucmerced.edu', 'ddevnich@ucmerced.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00d9ah105']
    },
    {
      id: 'ucop',
      short_name: 'UC Office of the President',
      long_name: 'University of California, Office of the President',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucop.edu', entity_domain: '.ucop.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00pjdza24']
    },
    {
      id: 'ucpress',
      short_name: 'UC Press',
      long_name: 'University of California Press',
      authentication: { strategy: nil }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: false,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: []
    },
    {
      id: 'ucr',
      short_name: 'UC Riverside',
      long_name: 'University of California, Riverside',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucr.edu', entity_domain: '.lib.ucr.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['katherine.koziar@ucr.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03nawhv43']
    },
    {
      id: 'ucsb',
      short_name: 'UC Santa Barbara',
      long_name: 'University of California, Santa Barbara',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucsb.edu', entity_domain: '.ucsb.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['rds@library.ucsb.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/02t274463']
    },
    {
      id: 'ucsc',
      short_name: 'UC Santa Cruz',
      long_name: 'University of California, Santa Cruz',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucsc.edu', entity_domain: '.library.ucsc.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03s65by71']
    },
    {
      id: 'ucsd',
      short_name: 'UC San Diego',
      long_name: 'University of California, San Diego',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucsd.edu', entity_domain: '.ucsd.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['tmarconi@ucsd.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/0168r3w48',
        'https://ror.org/01kbfgm16',
        'https://ror.org/04mg3nk07',
        'https://ror.org/05ffhwq07',
        'https://ror.org/04v7hvq31',
        'https://ror.org/01vf2g217'
      ]
    },
    {
      id: 'ucsf',
      short_name: 'UC San Francisco',
      long_name: 'University of California, San Francisco',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucsf.edu', entity_domain: '.ucsf.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['Ariel.Deardorff@ucsf.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/043mz5j54', 'https://ror.org/03hwe2705', 'https://ror.org/01t8svj65', 'https://ror.org/04g7y4303']
    },
    {
      id: 'uiuc',
      short_name: 'University of Illinois Urbana-Champaign',
      long_name: 'University of Illinois, Urbana-Champaign',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:uiuc.edu', entity_domain: 'uiuc.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/047426m28']
    },
    {
      id: 'umd',
      short_name: 'University of Maryland',
      long_name: 'University of Maryland, College Park',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:umd.edu', entity_domain: 'umd.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/047s2c258',
        'https://ror.org/042607708',
        'https://ror.org/02048n894',
        'https://ror.org/058cmd703',
        'https://ror.org/04xz38214',
        'https://ror.org/010prmy50'
      ]
    },
    {
      id: 'umn',
      short_name: 'University of Minnesota',
      long_name: 'University of Minnesota',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:umn.edu', entity_domain: 'umn.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['ljohnsto@umn.edu', 'datarepo@umn.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: [
        'https://ror.org/017zqws13',
        'https://ror.org/01hy4qx27',
        'https://ror.org/03grvy078',
        'https://ror.org/02rh4fw73',
        'https://ror.org/0241gfe92',
        'https://ror.org/04w6xt508',
        'https://ror.org/05vzqzh92',
        'https://ror.org/03e1ayz78',
        'https://ror.org/04jnprq39',
        'https://ror.org/05jc5ee02'
      ]
    },
    {
      id: 'unm',
      short_name: 'University of New Mexico',
      long_name: 'University of New Mexico',
      authentication: { strategy: 'shibboleth', entity_id: 'https://unmpidp.unm.edu/idp/shibboleth', entity_domain: 'unmpidp.unm.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/05fs6jp91', 'https://ror.org/01aq2mh35', 'https://ror.org/02jp62t23', 'https://ror.org/04skph061']
    },
    {
      id: 'unr',
      short_name: 'University of Nevada',
      long_name: 'University of Nevada, Reno',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp2.unr.edu/idp/shibboleth', entity_domain: 'unr.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01keh0577']
    },
    {
      id: 'uoregon',
      short_name: 'University of Oregon',
      long_name: 'University of Oregon',
      authentication: { strategy: 'shibboleth', entity_id: 'https://shibboleth.uoregon.edu/idp/shibboleth', entity_domain: 'uoregon.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/0293rh119']
    },
    {
      id: 'upenn',
      short_name: 'University of Pennsylvania',
      long_name: 'University of Pennsylvania',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idp.pennkey.upenn.edu/idp/shibboleth', entity_domain: 'upenn.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00b30xv10', 'https://ror.org/047939x15',
                 'https://ror.org/02917wp91', 'https://ror.org/04h81rw26']
    },
    {
      id: 'uri',
      short_name: 'University of Rhode Island',
      long_name: 'The University of Rhode Island',
      authentication: { strategy: 'shibboleth', entity_id: 'https://sts.windows.net/426d2a8d-9ccd-4255-893d-0686a32c168d/',
                        entity_domain: 'sts.windows.net' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: false,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/013ckk937']
    },
    {
      id: 'victoria',
      short_name: 'Victoria University, Melbourne',
      long_name: 'Victoria University, Melbourne',
      authentication: { strategy: 'shibboleth', entity_id: 'https://idpweb1.vu.edu.au/idp/shibboleth', entity_domain: 'idpweb1.vu.edu.au' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['Julie.gardner@vu.edu.au'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/04j757h9']
    },
    {
      id: 'washington',
      short_name: 'University of Washington',
      long_name: 'University of Washington',
      authentication: { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:washington.edu', entity_domain: 'washington.edu' }.to_json,
      campus_contacts: Rails.env.include?('production') ? ['jmuil@uw.edu', 'ebedford@uw.edu', 'abanders@uw.edu'].to_json : [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00cvxb145']
    },
    {
      id: 'wisc',
      short_name: 'University of Wisconsin–Madison',
      long_name: 'University of Wisconsin–Madison',
      authentication: { strategy: 'shibboleth', entity_id: 'https://login.wisc.edu/idp/shibboleth', entity_domain: 'login.wisc.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/01y2jtd41']
    },
    {
      id: 'yale',
      short_name: 'Yale',
      long_name: 'Yale University',
      authentication: { strategy: 'shibboleth', entity_id: 'https://auth.yale.edu/idp/shibboleth', entity_domain: 'auth.yale.edu' }.to_json,
      campus_contacts: [].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: true,
      covers_dpc: true,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/03v76x132', 'https://ror.org/03pnmqc26']
    }
  ].freeze

  desc 'Seed the tenants table'
  task seed: :environment do
    p 'Seeding the tenants table.'
    StashEngine::Tenant.all.destroy_all
    start_tenants.each do |tenant_hash|
      StashEngine::Tenant.create!(tenant_hash.except(:ror_orgs))
    end

    p 'Seeding the tenant_ror_orgs table'
    StashEngine::TenantRorOrg.all.destroy_all
    start_tenants.each do |tenant|
      tenant[:ror_orgs]&.each do |ror_id|
        StashEngine::TenantRorOrg.create!(tenant_id: tenant[:id], ror_id: ror_id)
      end
    end
  end

  desc 'Rename bad tenants'
  task :rename, [:dir] => :environment do |_task, args|
    if ApplicationRecord.connection.foreign_key_exists?(:stash_engine_tenant_ror_orgs, :stash_engine_tenants)
      ApplicationRecord.connection.remove_foreign_key :stash_engine_tenant_ror_orgs, :stash_engine_tenants, column: :tenant_id
    end
    if args.dir == 'reverse'
      p 'Reversing tenant id changes.'

      StashEngine::Tenant.find('shef').update(id: 'sheffield')
      StashEngine::TenantRorOrg.where(tenant_id: 'shef').update_all(tenant_id: 'sheffield')
      StashEngine::User.where(tenant_id: 'shef').update_all(tenant_id: 'sheffield')
      StashEngine::Resource.where(tenant_id: 'shef').update_all(tenant_id: 'sheffield')
      StashEngine::Identifier.where(payment_id: 'shef').update_all(payment_id: 'sheffield')
      StashEngine::Tenant.find('lbl').update(id: 'lbnl')
      StashEngine::TenantRorOrg.where(tenant_id: 'lbl').update_all(tenant_id: 'lbnl')
      StashEngine::User.where(tenant_id: 'lbl').update_all(tenant_id: 'lbnl')
      StashEngine::Resource.where(tenant_id: 'lbl').update_all(tenant_id: 'lbnl')
      StashEngine::Identifier.where(payment_id: 'lbl').update_all(payment_id: 'lbnl')
      StashEngine::Tenant.find('csueastbay').update(id: 'csueb')
      StashEngine::TenantRorOrg.where(tenant_id: 'csueastbay').update_all(tenant_id: 'csueb')
      StashEngine::User.where(tenant_id: 'csueastbay').update_all(tenant_id: 'csueb')
      StashEngine::Resource.where(tenant_id: 'csueastbay').update_all(tenant_id: 'csueb')
      StashEngine::Identifier.where(payment_id: 'csueastbay').update_all(payment_id: 'csueb')
      StashEngine::Tenant.find('vu').update(id: 'victoria')
      StashEngine::TenantRorOrg.where(tenant_id: 'vu').update_all(tenant_id: 'victoria')
      StashEngine::User.where(tenant_id: 'vu').update_all(tenant_id: 'victoria')
      StashEngine::Resource.where(tenant_id: 'vu').update_all(tenant_id: 'victoria')
      StashEngine::Identifier.where(payment_id: 'vu').update_all(payment_id: 'victoria')
      StashEngine::Tenant.find('unsw').update(id: 'sydneynsw')
      StashEngine::TenantRorOrg.where(tenant_id: 'unsw').update_all(tenant_id: 'sydneynsw')
      StashEngine::User.where(tenant_id: 'unsw').update_all(tenant_id: 'sydneynsw')
      StashEngine::Resource.where(tenant_id: 'unsw').update_all(tenant_id: 'sydneynsw')
      StashEngine::Identifier.where(payment_id: 'unsw').update_all(payment_id: 'sydneynsw')
      StashEngine::Tenant.find('osu').update(id: 'ohiostate')
      StashEngine::TenantRorOrg.where(tenant_id: 'osu').update_all(tenant_id: 'ohiostate')
      StashEngine::User.where(tenant_id: 'osu').update_all(tenant_id: 'ohiostate')
      StashEngine::Resource.where(tenant_id: 'osu').update_all(tenant_id: 'ohiostate')
      StashEngine::Identifier.where(payment_id: 'osu').update_all(payment_id: 'ohiostate')
      StashEngine::Tenant.find('msu').update(id: 'msu2')
      StashEngine::TenantRorOrg.where(tenant_id: 'msu').update_all(tenant_id: 'msu2')
      StashEngine::User.where(tenant_id: 'msu').update_all(tenant_id: 'msu2')
      StashEngine::Resource.where(tenant_id: 'msu').update_all(tenant_id: 'msu2')
      StashEngine::Identifier.where(payment_id: 'msu').update_all(payment_id: 'msu2')
      StashEngine::Tenant.find('montana').update(id: 'msu')
      StashEngine::TenantRorOrg.where(tenant_id: 'montana').update_all(tenant_id: 'msu')
      StashEngine::User.where(tenant_id: 'montana').update_all(tenant_id: 'msu')
      StashEngine::Resource.where(tenant_id: 'montana').update_all(tenant_id: 'msu')
      StashEngine::Identifier.where(payment_id: 'montana').update_all(payment_id: 'msu')

      # UC system
      StashEngine::Tenant.find('berkeley').update(id: 'ucb')
      StashEngine::TenantRorOrg.where(tenant_id: 'berkeley').update_all(tenant_id: 'ucb')
      StashEngine::User.where(tenant_id: 'berkeley').update_all(tenant_id: 'ucb')
      StashEngine::Resource.where(tenant_id: 'berkeley').update_all(tenant_id: 'ucb')
      StashEngine::Identifier.where(payment_id: 'berkeley').update_all(payment_id: 'ucb')
      StashEngine::Tenant.find('ucdavis').update(id: 'ucd')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucdavis').update_all(tenant_id: 'ucd')
      StashEngine::User.where(tenant_id: 'ucdavis').update_all(tenant_id: 'ucd')
      StashEngine::Resource.where(tenant_id: 'ucdavis').update_all(tenant_id: 'ucd')
      StashEngine::Identifier.where(payment_id: 'ucdavis').update_all(payment_id: 'ucd')
      StashEngine::Tenant.find('ucmerced').update(id: 'ucm')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucmerced').update_all(tenant_id: 'ucm')
      StashEngine::User.where(tenant_id: 'ucmerced').update_all(tenant_id: 'ucm')
      StashEngine::Resource.where(tenant_id: 'ucmerced').update_all(tenant_id: 'ucm')
      StashEngine::Identifier.where(payment_id: 'ucmerced').update_all(payment_id: 'ucm')

      # SUNY consortium
      StashEngine::Tenant.find('buffalo').update(id: 'suny-buffalo')
      StashEngine::TenantRorOrg.where(tenant_id: 'buffalo').update_all(tenant_id: 'suny-buffalo')
      StashEngine::User.where(tenant_id: 'buffalo').update_all(tenant_id: 'suny-buffalo')
      StashEngine::Resource.where(tenant_id: 'buffalo').update_all(tenant_id: 'suny-buffalo')
      StashEngine::Identifier.where(payment_id: 'buffalo').update_all(payment_id: 'suny-buffalo')
      StashEngine::Tenant.find('buffalostate').update(id: 'suny-buffalostate')
      StashEngine::TenantRorOrg.where(tenant_id: 'buffalostate').update_all(tenant_id: 'suny-buffalostate')
      StashEngine::User.where(tenant_id: 'buffalostate').update_all(tenant_id: 'suny-buffalostate')
      StashEngine::Resource.where(tenant_id: 'buffalostate').update_all(tenant_id: 'suny-buffalostate')
      StashEngine::Identifier.where(payment_id: 'buffalostate').update_all(payment_id: 'suny-buffalostate')
      StashEngine::Tenant.find('downstate').update(id: 'suny-downstate')
      StashEngine::TenantRorOrg.where(tenant_id: 'downstate').update_all(tenant_id: 'suny-downstate')
      StashEngine::User.where(tenant_id: 'downstate').update_all(tenant_id: 'suny-downstate')
      StashEngine::Resource.where(tenant_id: 'downstate').update_all(tenant_id: 'suny-downstate')
      StashEngine::Identifier.where(payment_id: 'downstate').update_all(payment_id: 'suny-downstate')
      StashEngine::Tenant.find('fredonia').update(id: 'suny-fredonia')
      StashEngine::TenantRorOrg.where(tenant_id: 'fredonia').update_all(tenant_id: 'suny-fredonia')
      StashEngine::User.where(tenant_id: 'fredonia').update_all(tenant_id: 'suny-fredonia')
      StashEngine::Resource.where(tenant_id: 'fredonia').update_all(tenant_id: 'suny-fredonia')
      StashEngine::Identifier.where(payment_id: 'fredonia').update_all(payment_id: 'suny-fredonia')
      StashEngine::Tenant.find('geneseo').update(id: 'suny-geneseo')
      StashEngine::TenantRorOrg.where(tenant_id: 'geneseo').update_all(tenant_id: 'suny-geneseo')
      StashEngine::User.where(tenant_id: 'geneseo').update_all(tenant_id: 'suny-geneseo')
      StashEngine::Resource.where(tenant_id: 'geneseo').update_all(tenant_id: 'suny-geneseo')
      StashEngine::Identifier.where(payment_id: 'geneseo').update_all(payment_id: 'suny-geneseo')
      StashEngine::Tenant.find('stonybrook').update(id: 'suny-stonybrook')
      StashEngine::TenantRorOrg.where(tenant_id: 'stonybrook').update_all(tenant_id: 'suny-stonybrook')
      StashEngine::User.where(tenant_id: 'stonybrook').update_all(tenant_id: 'suny-stonybrook')
      StashEngine::Resource.where(tenant_id: 'stonybrook').update_all(tenant_id: 'suny-stonybrook')
      StashEngine::Identifier.where(payment_id: 'stonybrook').update_all(payment_id: 'suny-stonybrook')

      # Clare consortium
      StashEngine::Tenant.find('claremont').update(id: 'clare-cs')
      StashEngine::Tenant.where(sponsor_id: 'claremont').update_all(sponsor_id: 'clare-cs')
      StashEngine::TenantRorOrg.where(tenant_id: 'claremont').update_all(tenant_id: 'clare-cs')
      StashEngine::User.where(tenant_id: 'claremont').update_all(tenant_id: 'clare-cs')
      StashEngine::Resource.where(tenant_id: 'claremont').update_all(tenant_id: 'clare-cs')
      StashEngine::Identifier.where(payment_id: 'claremont').update_all(payment_id: 'clare-cs')
      StashEngine::Tenant.find('cgu').update(id: 'clare-cgu')
      StashEngine::TenantRorOrg.where(tenant_id: 'cgu').update_all(tenant_id: 'clare-cgu')
      StashEngine::User.where(tenant_id: 'cgu').update_all(tenant_id: 'clare-cgu')
      StashEngine::Resource.where(tenant_id: 'cgu').update_all(tenant_id: 'clare-cgu')
      StashEngine::Identifier.where(payment_id: 'cgu').update_all(payment_id: 'clare-cgu')
      StashEngine::Tenant.find('cmc').update(id: 'clare-cmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'cmc').update_all(tenant_id: 'clare-cmc')
      StashEngine::User.where(tenant_id: 'cmc').update_all(tenant_id: 'clare-cmc')
      StashEngine::Resource.where(tenant_id: 'cmc').update_all(tenant_id: 'clare-cmc')
      StashEngine::Identifier.where(payment_id: 'cmc').update_all(payment_id: 'clare-cmc')
      StashEngine::Tenant.find('hmc').update(id: 'clare-hmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'hmc').update_all(tenant_id: 'clare-hmc')
      StashEngine::User.where(tenant_id: 'hmc').update_all(tenant_id: 'clare-hmc')
      StashEngine::Resource.where(tenant_id: 'hmc').update_all(tenant_id: 'clare-hmc')
      StashEngine::Identifier.where(payment_id: 'hmc').update_all(payment_id: 'clare-hmc')
      StashEngine::Tenant.find('kgi').update(id: 'clare-kgi')
      StashEngine::TenantRorOrg.where(tenant_id: 'kgi').update_all(tenant_id: 'clare-kgi')
      StashEngine::User.where(tenant_id: 'kgi').update_all(tenant_id: 'clare-kgi')
      StashEngine::Resource.where(tenant_id: 'kgi').update_all(tenant_id: 'clare-kgi')
      StashEngine::Identifier.where(payment_id: 'kgi').update_all(payment_id: 'clare-kgi')
      StashEngine::Tenant.find('pitzer').update(id: 'clare-pitzer')
      StashEngine::TenantRorOrg.where(tenant_id: 'pitzer').update_all(tenant_id: 'clare-pitzer')
      StashEngine::User.where(tenant_id: 'pitzer').update_all(tenant_id: 'clare-pitzer')
      StashEngine::Resource.where(tenant_id: 'pitzer').update_all(tenant_id: 'clare-pitzer')
      StashEngine::Identifier.where(payment_id: 'pitzer').update_all(payment_id: 'clare-pitzer')
      StashEngine::Tenant.find('pomona').update(id: 'clare-pomona')
      StashEngine::TenantRorOrg.where(tenant_id: 'pomona').update_all(tenant_id: 'clare-pomona')
      StashEngine::User.where(tenant_id: 'pomona').update_all(tenant_id: 'clare-pomona')
      StashEngine::Resource.where(tenant_id: 'pomona').update_all(tenant_id: 'clare-pomona')
      StashEngine::Identifier.where(payment_id: 'pomona').update_all(payment_id: 'clare-pomona')
      StashEngine::Tenant.find('scrippscollege').update(id: 'clare-scripps')
      StashEngine::TenantRorOrg.where(tenant_id: 'scrippscollege').update_all(tenant_id: 'clare-scripps')
      StashEngine::User.where(tenant_id: 'scrippscollege').update_all(tenant_id: 'clare-scripps')
      StashEngine::Resource.where(tenant_id: 'scrippscollege').update_all(tenant_id: 'clare-scripps')
      StashEngine::Identifier.where(payment_id: 'scrippscollege').update_all(payment_id: 'clare-scripps')
    else
      p 'Correcting tenant ids.'

      StashEngine::Tenant.find('victoria').update(id: 'vu')
      StashEngine::TenantRorOrg.where(tenant_id: 'victoria').update_all(tenant_id: 'vu')
      StashEngine::User.where(tenant_id: 'victoria').update_all(tenant_id: 'vu')
      StashEngine::Resource.where(tenant_id: 'victoria').update_all(tenant_id: 'vu')
      StashEngine::Identifier.where(payment_id: 'victoria').update_all(payment_id: 'vu')
      StashEngine::Tenant.find('msu').update(id: 'montana')
      StashEngine::TenantRorOrg.where(tenant_id: 'msu').update_all(tenant_id: 'montana')
      StashEngine::User.where(tenant_id: 'msu').update_all(tenant_id: 'montana')
      StashEngine::Resource.where(tenant_id: 'msu').update_all(tenant_id: 'montana')
      StashEngine::Identifier.where(payment_id: 'msu').update_all(payment_id: 'montana')
      StashEngine::Tenant.find('msu2').update(id: 'msu')
      StashEngine::TenantRorOrg.where(tenant_id: 'msu2').update_all(tenant_id: 'msu')
      StashEngine::User.where(tenant_id: 'msu2').update_all(tenant_id: 'msu')
      StashEngine::Resource.where(tenant_id: 'msu2').update_all(tenant_id: 'msu')
      StashEngine::Identifier.where(payment_id: 'msu2').update_all(payment_id: 'msu')
      StashEngine::Tenant.find('ohiostate').update(id: 'osu')
      StashEngine::TenantRorOrg.where(tenant_id: 'ohiostate').update_all(tenant_id: 'osu')
      StashEngine::User.where(tenant_id: 'ohiostate').update_all(tenant_id: 'osu')
      StashEngine::Resource.where(tenant_id: 'ohiostate').update_all(tenant_id: 'osu')
      StashEngine::Identifier.where(payment_id: 'ohiostate').update_all(payment_id: 'osu')
      StashEngine::Tenant.find('sydneynsw').update(id: 'unsw')
      StashEngine::TenantRorOrg.where(tenant_id: 'sydneynsw').update_all(tenant_id: 'unsw')
      StashEngine::User.where(tenant_id: 'sydneynsw').update_all(tenant_id: 'unsw')
      StashEngine::Resource.where(tenant_id: 'sydneynsw').update_all(tenant_id: 'unsw')
      StashEngine::Identifier.where(payment_id: 'sydneynsw').update_all(payment_id: 'unsw')
      StashEngine::Tenant.find('csueb').update(id: 'csueastbay')
      StashEngine::TenantRorOrg.where(tenant_id: 'csueb').update_all(tenant_id: 'csueastbay')
      StashEngine::User.where(tenant_id: 'csueb').update_all(tenant_id: 'csueastbay')
      StashEngine::Resource.where(tenant_id: 'csueb').update_all(tenant_id: 'csueastbay')
      StashEngine::Identifier.where(payment_id: 'csueb').update_all(payment_id: 'csueastbay')
      StashEngine::Tenant.find('lbnl').update(id: 'lbl')
      StashEngine::TenantRorOrg.where(tenant_id: 'lbnl').update_all(tenant_id: 'lbl')
      StashEngine::User.where(tenant_id: 'lbnl').update_all(tenant_id: 'lbl')
      StashEngine::Resource.where(tenant_id: 'lbnl').update_all(tenant_id: 'lbl')
      StashEngine::Identifier.where(payment_id: 'lbnl').update_all(payment_id: 'lbl')
      StashEngine::Tenant.find('sheffield').update(id: 'shef')
      StashEngine::TenantRorOrg.where(tenant_id: 'sheffield').update_all(tenant_id: 'shef')
      StashEngine::User.where(tenant_id: 'sheffield').update_all(tenant_id: 'shef')
      StashEngine::Resource.where(tenant_id: 'sheffield').update_all(tenant_id: 'shef')
      StashEngine::Identifier.where(payment_id: 'sheffield').update_all(payment_id: 'shef')

      # Clare consortium
      StashEngine::Tenant.find('clare-cs').update(id: 'claremont')
      StashEngine::Tenant.where(sponsor_id: 'clare-cs').update_all(sponsor_id: 'claremont')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-cs').update_all(tenant_id: 'claremont')
      StashEngine::User.where(tenant_id: 'clare-cs').update_all(tenant_id: 'claremont')
      StashEngine::Resource.where(tenant_id: 'clare-cs').update_all(tenant_id: 'claremont')
      StashEngine::Identifier.where(payment_id: 'clare-cs').update_all(payment_id: 'claremont')
      StashEngine::Tenant.find('clare-cgu').update(id: 'cgu')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-cgu').update_all(tenant_id: 'cgu')
      StashEngine::User.where(tenant_id: 'clare-cgu').update_all(tenant_id: 'cgu')
      StashEngine::Resource.where(tenant_id: 'clare-cgu').update_all(tenant_id: 'cgu')
      StashEngine::Identifier.where(payment_id: 'clare-cgu').update_all(payment_id: 'cgu')
      StashEngine::Tenant.find('clare-cmc').update(id: 'cmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-cmc').update_all(tenant_id: 'cmc')
      StashEngine::User.where(tenant_id: 'clare-cmc').update_all(tenant_id: 'cmc')
      StashEngine::Resource.where(tenant_id: 'clare-cmc').update_all(tenant_id: 'cmc')
      StashEngine::Identifier.where(payment_id: 'clare-cmc').update_all(payment_id: 'cmc')
      StashEngine::Tenant.find('clare-hmc').update(id: 'hmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-hmc').update_all(tenant_id: 'hmc')
      StashEngine::User.where(tenant_id: 'clare-hmc').update_all(tenant_id: 'hmc')
      StashEngine::Resource.where(tenant_id: 'clare-hmc').update_all(tenant_id: 'hmc')
      StashEngine::Identifier.where(payment_id: 'clare-hmc').update_all(payment_id: 'hmc')
      StashEngine::Tenant.find('clare-kgi').update(id: 'kgi')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-kgi').update_all(tenant_id: 'kgi')
      StashEngine::User.where(tenant_id: 'clare-kgi').update_all(tenant_id: 'kgi')
      StashEngine::Resource.where(tenant_id: 'clare-kgi').update_all(tenant_id: 'kgi')
      StashEngine::Identifier.where(payment_id: 'clare-kgi').update_all(payment_id: 'kgi')
      StashEngine::Tenant.find('clare-pitzer').update(id: 'pitzer')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-pitzer').update_all(tenant_id: 'pitzer')
      StashEngine::User.where(tenant_id: 'clare-pitzer').update_all(tenant_id: 'pitzer')
      StashEngine::Resource.where(tenant_id: 'clare-pitzer').update_all(tenant_id: 'pitzer')
      StashEngine::Identifier.where(payment_id: 'clare-pitzer').update_all(payment_id: 'pitzer')
      StashEngine::Tenant.find('clare-pomona').update(id: 'pomona')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-pomona').update_all(tenant_id: 'pomona')
      StashEngine::User.where(tenant_id: 'clare-pomona').update_all(tenant_id: 'pomona')
      StashEngine::Resource.where(tenant_id: 'clare-pomona').update_all(tenant_id: 'pomona')
      StashEngine::Identifier.where(payment_id: 'clare-pomona').update_all(payment_id: 'pomona')
      StashEngine::Tenant.find('clare-scripps').update(id: 'scrippscollege')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-scripps').update_all(tenant_id: 'scrippscollege')
      StashEngine::User.where(tenant_id: 'clare-scripps').update_all(tenant_id: 'scrippscollege')
      StashEngine::Resource.where(tenant_id: 'clare-scripps').update_all(tenant_id: 'scrippscollege')
      StashEngine::Identifier.where(payment_id: 'clare-scripps').update_all(payment_id: 'scrippscollege')

      # SUNY consortium
      StashEngine::Tenant.find('suny-buffalo').update(id: 'buffalo')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-buffalo').update_all(tenant_id: 'buffalo')
      StashEngine::User.where(tenant_id: 'suny-buffalo').update_all(tenant_id: 'buffalo')
      StashEngine::Resource.where(tenant_id: 'suny-buffalo').update_all(tenant_id: 'buffalo')
      StashEngine::Identifier.where(payment_id: 'suny-buffalo').update_all(payment_id: 'buffalo')
      StashEngine::Tenant.find('suny-buffalostate').update(id: 'buffalostate')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-buffalostate').update_all(tenant_id: 'buffalostate')
      StashEngine::User.where(tenant_id: 'suny-buffalostate').update_all(tenant_id: 'buffalostate')
      StashEngine::Resource.where(tenant_id: 'suny-buffalostate').update_all(tenant_id: 'buffalostate')
      StashEngine::Identifier.where(payment_id: 'suny-buffalostate').update_all(payment_id: 'buffalostate')
      StashEngine::Tenant.find('suny-downstate').update(id: 'downstate')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-downstate').update_all(tenant_id: 'downstate')
      StashEngine::User.where(tenant_id: 'suny-downstate').update_all(tenant_id: 'downstate')
      StashEngine::Resource.where(tenant_id: 'suny-downstate').update_all(tenant_id: 'downstate')
      StashEngine::Identifier.where(payment_id: 'suny-downstate').update_all(payment_id: 'downstate')
      StashEngine::Tenant.find('suny-fredonia').update(id: 'fredonia')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-fredonia').update_all(tenant_id: 'fredonia')
      StashEngine::User.where(tenant_id: 'suny-fredonia').update_all(tenant_id: 'fredonia')
      StashEngine::Resource.where(tenant_id: 'suny-fredonia').update_all(tenant_id: 'fredonia')
      StashEngine::Identifier.where(payment_id: 'suny-fredonia').update_all(payment_id: 'fredonia')
      StashEngine::Tenant.find('suny-geneseo').update(id: 'geneseo')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-geneseo').update_all(tenant_id: 'geneseo')
      StashEngine::User.where(tenant_id: 'suny-geneseo').update_all(tenant_id: 'geneseo')
      StashEngine::Resource.where(tenant_id: 'suny-geneseo').update_all(tenant_id: 'geneseo')
      StashEngine::Identifier.where(payment_id: 'suny-geneseo').update_all(payment_id: 'geneseo')
      StashEngine::Tenant.find('suny-stonybrook').update(id: 'stonybrook')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-stonybrook').update_all(tenant_id: 'stonybrook')
      StashEngine::User.where(tenant_id: 'suny-stonybrook').update_all(tenant_id: 'stonybrook')
      StashEngine::Resource.where(tenant_id: 'suny-stonybrook').update_all(tenant_id: 'stonybrook')
      StashEngine::Identifier.where(payment_id: 'suny-stonybrook').update_all(payment_id: 'stonybrook')

      # UC system
      StashEngine::Tenant.find('ucb').update(id: 'berkeley')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucb').update_all(tenant_id: 'berkeley')
      StashEngine::User.where(tenant_id: 'ucb').update_all(tenant_id: 'berkeley')
      StashEngine::Resource.where(tenant_id: 'ucb').update_all(tenant_id: 'berkeley')
      StashEngine::Identifier.where(payment_id: 'ucb').update_all(payment_id: 'berkeley')
      StashEngine::Tenant.find('ucd').update(id: 'ucdavis')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucd').update_all(tenant_id: 'ucdavis')
      StashEngine::User.where(tenant_id: 'ucd').update_all(tenant_id: 'ucdavis')
      StashEngine::Resource.where(tenant_id: 'ucd').update_all(tenant_id: 'ucdavis')
      StashEngine::Identifier.where(payment_id: 'ucd').update_all(payment_id: 'ucdavis')
      StashEngine::Tenant.find('ucm').update(id: 'ucmerced')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucm').update_all(tenant_id: 'ucmerced')
      StashEngine::User.where(tenant_id: 'ucm').update_all(tenant_id: 'ucmerced')
      StashEngine::Resource.where(tenant_id: 'ucm').update_all(tenant_id: 'ucmerced')
      StashEngine::Identifier.where(payment_id: 'ucm').update_all(payment_id: 'ucmerced')
    end
    unless ApplicationRecord.connection.foreign_key_exists?(:stash_engine_tenant_ror_orgs, :stash_engine_tenants)
      ApplicationRecord.connection.add_foreign_key :stash_engine_tenant_ror_orgs, :stash_engine_tenants, column: :tenant_id
    end
  rescue StandardError => e
    p e
    p 'Tenants ids not changed from original'
  end
end
# rubocop:enable Metrics/BlockLength
