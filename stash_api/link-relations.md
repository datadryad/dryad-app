# Dash link relations
Note, the items below talk about Stash which is the software that the Dash system runs.

**TO DO:** Find real link relations to replace as many of these as possible.

## [stash:datasets](#stash-datasets)

| curie | meaning |
| ----- | ------- |
| stash:datasets | the list of datasets in Stash |

## [stash:dataset](#stash-dataset)

| curie | meaning |
| ----- | ------- |
| stash:dataset | a single Stash dataset |

## [stash:versions](#stash-versions)

| curie | meaning |
| ----- | ------- |
| stash:versions | the versions of a dataset in Stash |

## [stash:version](#stash-version)

| curie | meaning |
| ----- | ------- |
| stash:version | a single version of a Stash dataset |

## [stash:files](#stash-files)

| curie | meaning |
| ----- | ------- |
| stash:files | the list and information about files in a dataset version |

## [stash:file](#stash-file)

| curie | meaning |
| ----- | ------- |
| stash:file | information about a file in a dataset version |

## [stash:download](#stash-download)

| curie | meaning |
| ----- | ------- |
| stash:download | download link for the content of a data file, or the zip archive of a datset |

---

**TO DO:** Figure out how to handle DataCite relation types. Can all related identifiers
be converted to a URI? If so, we should get rid of the `relatedWorks` type and instead just
use links (though we'll have to define our own link relations, since DataCite documentation
is an opaque PDF we can't link into).
