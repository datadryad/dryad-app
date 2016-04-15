# stash-sword

A minimal SWORD 2.0 connector providing those features needed for Stash.

## Command-line test client usage

### Submit:

```bash
Usage: create [options]
    -h, --help                       display this help and exit
    -u, --username USERNAME          submit as user USERNAME
    -p, --password PASSWORD          submit with password PASSWORD
    -o, --on-behalf-of OTHER         submit on behalf of user OTHER
    -z, --zipfile ZIPFILE            submit zipfile ZIPFILE
    -d, --doi DOI                    submit with doi DOI
    -c, --collection-uri URI         submit to collection uri URI

$ bundle exec create.rb \
  -u ucb_dash_submitter \
  -p [PASSWORD] \
  -c http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/dash_ucb \
  -z examples/uploads/example.zip \
  -d doi:10.5072/FK20160415dmoles

HTTP 201 Created
server = Apache-Coyote/1.1
location = http://merritt.cdlib.org/sword/v2/object/doi:10.5072/FK20160415dmoles
last-modified = Fri, 15 Apr 2016 11:18:07 -0700
content-md5 = 7af11936d3bbe2a7688aafbf0f22cf8e
content-type = application/atom+xml; type=entry;charset=UTF-8
transfer-encoding = chunked
date = Fri, 15 Apr 2016 18:18:07 GMT

<entry xmlns="http://www.w3.org/2005/Atom"><id>http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4nc66m7x</id><author><name>ucb_dash_submitter</name></author><generator uri="http://www.swordapp.org/" version="2.0" /><link href="http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4nc66m7x" rel="edit" /><link href="http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4nc66m7x" rel="http://purl.org/net/sword/terms/add" /><link href="http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4nc66m7x" rel="edit-media" /><treatment xmlns="http://purl.org/net/sword/terms/">no treatment information available</treatment></entry>

EM-IRI: http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4nc66m7x
SE-IRI: http://merritt.cdlib.org/sword/v2/object/ark:/99999/fk4nc66m7x
Edit-IRI: http://merritt.cdlib.org/sword/v2/object/doi:10.5072/FK20160415dmoles
```

**Note:** The last URI listed, the **Edit-IRI**, is the one used for the `update` command.

**Note:** The help output for `create.rb` shows both the `--collection-uri` and `--edit-iri` options,
even though only `--collection-uri` is used.

### Update:

**Note:** According to the SWORD 2.0 spec, the **Edit-IRI** should be taken from the **Location**
header of the `create.rb` response.

```bash
Usage: update [options]
    -h, --help                       display this help and exit
    -u, --username USERNAME          submit as user USERNAME
    -p, --password PASSWORD          submit with password PASSWORD
    -o, --on-behalf-of OTHER         submit on behalf of user OTHER
    -z, --zipfile ZIPFILE            submit zipfile ZIPFILE
    -d, --doi DOI                    submit with doi DOI
    -e, --edit-iri EDIT_IRI          submit to Edit-Iri EDIT_IRI

$ bundle exec update.rb \
  -u ucb_dash_submitter \
  -p [PASSWORD] \
  -e http://merritt.cdlib.org/sword/v2/object/doi:10.5072/FK20160415dmoles \
  -z examples/uploads/example.zip \
  -d doi:10.5072/FK20160415dmoles
```

**Note:** Currently `update.rb` returns a `302 Found` response; we still need to do some work
to handle the redirection proerly, probably rewriting `Client#send_update` to use the `RestClient`
gem (the way `post_create` does) rather than raw `Net::HTTP`.

**Note:** The help output for `create.rb` shows both the `--edit-iri` and `--collection-uri` options,
even though only `--edit-iri` is used.
