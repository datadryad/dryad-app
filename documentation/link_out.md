# Generating files for NCBI linkout

## Overview

[NCBI LinkOut](https://www.ncbi.nlm.nih.gov/projects/linkout/) and [European PMC LabsLink](http://europepmc.org/LabsLink) are mechanisms by which NCBI and PMC pages link to content in Dryad. Dryad data packages are related to articles in PubMed, and to molecular sequences in GenBank's nucleotide and protein databases.

The core service code lives in the
[Dryad-app repo](https://github.com/CDL-Dryad/dryad-app/tree/main) in
the `lib/stash/link_out/` directory. The rake taks
live in `lib/tasks/link_out.rake`. The XML ERB
templates however reside within the higher-level `app/views/link_out/`
directory due to an issue with the Rails engine having trouble
locating views in an engine when executing within the context of a
Rake task. 

The FTP credentials used by the services is stored in the application's private repository

To create and publish the LinkOut files, run the following command:
  `bundle exec rails link_out:publish RAILS_ENV=[environment]`

The LinkOut services were derived from the [original Dryad java implementation](https://github.com/datadryad/dryad-linkout-tool).

## NCBI Pubmed LinkOut Files

Any Dryad dataset, whose metadata is publicly visible (published|embargoed curation status), that has a PubMed ID defined in the `stash_engine_internal_data` table will appear in the LinkOut files.

The `pubmed_service` performs 3 important functions:
- It retrieves PubMed IDs from the NCBI api when the user provides a publication DOI on the dataset entry page.
- It generates the `providerinfo.xml` and `pubmedlinkout.xml` files.
- Pushes the files to the LinkOut FTP server

PubMed IDs that are retrieved by this service are stored in the `stash_engine_internal_data` table with a `data_type = 'pubmedID'`.

Once the dataset becomes published or embargoed it will appear in the `pubmedlinkout.xml` file.

Sample `providerinfo.xml` file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Dryad LinkOut Provider file for PubMed -->
<!DOCTYPE Provider PUBLIC "-//NLM//DTD LinkOut 1.0//EN" "LinkOut.dtd">
<Provider>
  <ProviderId>1234</ProviderId>
  <Name>Dryad Data Platform</Name>
  <NameAbbr>dryaddb</NameAbbr>
  <Url>http://datadryad.org/</Url>
  <Brief>Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.</Brief>
</Provider>
```

Sample `pubmedlinkout.xml` file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Dryad LinkOut Links file for PubMed -->
<!DOCTYPE LinkSet PUBLIC "-//NLM//DTD LinkOut 1.0//EN" "LinkOut.dtd">
<LinkSet>
  <Link>
    <LinkId>dryad.pubmed.2019-05-30</LinkId>
    <ProviderId>1234</ProviderId>
    <IconUrl>http://datadryad.org/images/DryadLogo-Button.png</IconUrl>
    <ObjectSelector>
      <Database>PubMed</Database>
      <ObjectList>
        <ObjId>12345678</ObjId> <!-- doi:12.1234/dryad.12345a -->
        <ObjId>90123456</ObjId> <!-- doi:12.1234/dryad.12345b -->
      </ObjectList>
    </ObjectSelector>
    <ObjectUrl>
      <Base>http://datadryad.org/discover?</Base>
      <Rule>query=%22&amp;lo.doi;%22</Rule>
      <SubjectType>supplemental materials</SubjectType>
    </ObjectUrl>
  </Link>
</LinkSet>
```

## Europe PubMed Central (PMC) LabsLink Files

Any Dryad dataset, whose metadata is publicly visible (published|embargoed curation status), that has a PubMed ID defined in the `stash_engine_internal_data` table will appear in the LabsLink files.

The `labslink_service` performs 2 important functions:
- It generates the `labslink-profile.xml` and `labslink-links.xml` files.
- Pushes the files to the LabsLink FTP server

Sample `labslink-profile.xml` file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Dryad LinkOut Provider file for European PubMed Central LabsLink -->
<providers>
  <provider>
    <id>1234</id>
    <resourceName>Dryad Data Platform</resourceName>
    <description>Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.</description>
    <email>example@example.org</email>
  </provider>
</providers>
```

Sample `labslink-links.xml` file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Dryad LinkOut Links file for European PubMed Central LabsLink -->
<links>
  <link providerId="1234">
    <resource>
      <title>Data from: A really important study of IPA selection process of male bipeds in the Northern California region.</title>
      <url>http://dx.doi.org/doi:12.1234/dryad.12345a</url>
    </resource>
    <record>
      <source>MED</source>
      <id>12345678</id>
    </record>
  </link>
  <link providerId="1234">
    <resource>
      <title>Data from: The most data dense dataset in all of dataset history.</title>
      <url>http://dx.doi.org/doi:12.1234/dryad.12345b</url>
    </resource>
    <record>
      <source>MED</source>
      <id>90123456</id>
    </record>
  </link>
</links>
```

## NCBI GenBank Sequence Files

Any Dryad dataset, whose metadata is publicly visible (published|embargoed curation status), that has GenBank database records defined in `stash_engine_external_references` will appear in the GenBank sequence files.

The `pubmed_sequence_service` performs 2 important functions:
- It retrieves GenBank Sequence IDs from the NCBI api when the user provides a publication DOI on the dataset entry page if the `pubmed_service` found a corresponding PubMed ID.
- It generates the `sequencelinkout0000[n][n].xml` files.

The sequence files are broken out into multiple files due to LinkOut limitations on file size.

Sample `sequencelinkout000001.xml` file:
```xml
<?xml version="1.0"?>
<!-- Dryad LinkOut Links file for Pubmed GenBank Sequence -->
<!DOCTYPE LinkSet PUBLIC "-//NLM//DTD LinkOut 1.0//EN" "LinkOut.dtd">
<LinkSet>
  <Link>
    <LinkId>dryad.seq.2019-05-30.0</LinkId>
    <ProviderId>1234</ProviderId>
    <IconUrl>http://dryad-dev.cdlib.org/images/DryadLogo-Button.png</IconUrl>
    <ObjectSelector>
      <Database>bioproject</Database>
      <ObjectList>
        <ObjId>396001</ObjId>
      </ObjectList>
    </ObjectSelector>
    <ObjectUrl>
      <Base>http://dryad-dev.cdlib.org/stash/dataset/</Base>
      <Rule>doi:12.1234/dryad.12345a</Rule>
      <SubjectType>supplemental materials</SubjectType>
    </ObjectUrl>
  </Link>
  <Link>
    <LinkId>dryad.seq.2019-05-30.0</LinkId>
    <ProviderId>1234</ProviderId>
    <IconUrl>http://dryad-dev.cdlib.org/images/DryadLogo-Button.png</IconUrl>
    <ObjectSelector>
      <Database>gene</Database>
      <ObjectList>
        <ObjId>4579</ObjId>
        <ObjId>4578</ObjId>
        <ObjId>4577</ObjId>
        <ObjId>4576</ObjId>
        <ObjId>4575</ObjId>
        <ObjId>4574</ObjId>
        <ObjId>4573</ObjId>
        <ObjId>4572</ObjId>
        <ObjId>4571</ObjId>
      </ObjectList>
    </ObjectSelector>
    <ObjectUrl>
      <Base>http://dryad-dev.cdlib.org/stash/dataset/</Base>
      <Rule>doi:12.1234/dryad.12345a</Rule>
      <SubjectType>supplemental materials</SubjectType>
    </ObjectUrl>
  </Link>
  <Link>
    <LinkId>dryad.seq.2019-05-30.1</LinkId>
    <ProviderId>1234</ProviderId>
    <IconUrl>http://dryad-dev.cdlib.org/images/DryadLogo-Button.png</IconUrl>
    <ObjectSelector>
      <Database>gene</Database>
      <ObjectList>
          <ObjId>106956427</ObjId>
          <ObjId>106945045</ObjId>
      </ObjectList>
    </ObjectSelector>
    <ObjectUrl>
      <Base>http://dryad-dev.cdlib.org/stash/dataset/</Base>
      <Rule>doi:12.1234/dryad.12345b</Rule>
      <SubjectType>supplemental materials</SubjectType>
    </ObjectUrl>
  </Link>
</LinkSet>
```

## Other available rake tasks

The following rake tasks are available to seed the database with PubMed IDs and GenBank sequences, create files individually, and push them to the appropriate FTP server(s)

```shell
rails link_out:create                                # Generate the LinkOut file(s)
rails link_out:create_labslink_linkouts              # Generate the LabsLink LinkOut files
rails link_out:create_pubmed_linkouts                # Generate the PubMed Link Out files
rails link_out:create_pubmed_sequence_linkouts       # Generate the PubMed GenBank Sequence LinkOut files
rails link_out:push                                  # Push the LinkOut files to the LinkOut FTP servers

rails link_out:publish                               # Generate and then push the LinkOut file(s) to the LinkOut FTP servers

rails link_out:seed_genbank_ids                      # Seed existing datasets with GenBank Sequence Ids - WARNING: this will query the API for each dataset that has a pubmedID
rails link_out:seed_pmids                            # Seed existing datasets with PubMed Ids - WARNING: this will query the API for each dataset that has a publicationDOI
rails link_out:seed_solr_keywords                    # Update Solr keywords with publication IDs
```
