<% @page_title = 'Discovering data on Dryad' %>
<h1>Searching for data</h1>

You can search for Dryad data via our [search API](/api#?route=get-/search), or by using our [search interface](/search). There is a data search box on every Dryad web page.


## Search syntax

Dryad's search checks for the main text query within most of the metadata fields of each dataset, including the title and abstract. Special syntax can help you retrieve the exact results desired from a search query:

 * Use quotation marks around your terms to search for an exact phrase (e.g., [`"Dryad data"`](/search?q="Dryad+data"))
 * Terms may include an * at the end to indicate a wildcard, (e.g., [`biolog*`](/search?q=biolog*) retrieves results including *biology*, *biological*, *biologist*, etc.)
 * A term may be negated with ` NOT ` or ` -` to indicate that it should not be present in the results (e.g., [`Dryad -data`](/search?q=Dryad+-data))


## Filters

Dryad search results can be refined with filters.

On the left side of the search results page, options are available to filter your search by associated research organizations, journals, publication date, available file extensions, and subject keywords. For each category, the top 10 options by frequency in the current set of search results will be presented.


### Advanced search

More extensive and detailed search and filter options are available on the [Advanced search page](/search/advanced). These options include:

 * Selecting research organizations and journals for filtering beyond those in the initial filter list
 * Using free text to search within dataset subject keywords
 * Using funding award numbers and related work identifiers to search for datasets
 * Searching for dataset authors with their name or ORCID
 * Searching for datasets with data file downloads in a specific size range


## Dryad API

Search queries and filters can be used interchangably in the [search interface](/search) and the [Dryad search API](/api#?route=get-/search). 

Search URLs created in our search interface can be used on the Dryad search API by replacing `https://datadryad.org/` with `https://datadryad.org/api/v2/`. 

For example, [this search for datasets associated with Dryad](/search?org=https%3A%2F%2Fror.org%2F00x6h5n95) through author affiliations or funding retrieves [the same results, in JSON format](/api/v2/search?org=https%3A%2F%2Fror.org%2F00x6h5n95), via the API. Compare the URLs:

- `https://datadryad.org/search?org=https%3A%2F%2Fror.org%2F00x6h5n95`
- `https://datadryad.org/api/v2/search?org=https%3A%2F%2Fror.org%2F00x6h5n95`


## Collected works

By filtering Dryad datasets based on journal, research organization, or author ORCID, users can retrieve the collected works on Dryad for each of these entities. Dataset landing pages link directly to many of these collected works pages. The resulting searches can be further refined with additional filters.

When an organization is included as a search filter, the organization's name and a link to the organization's [ROR record](https://ror.org/) is displayed on the results page. See [the collected works associated with the U.S. National Institutes of Health](/search?org=https%3A%2F%2Fror.org%2F01cwqze88).

### Author profile pages

Clicking an author name on a dataset landing page, or using the author ORCID filter on our [advanced search](/search/advanced), leads to the Dryad collected works page for the author (see an [example author collected works page](https://datadryad.org/search?orcid=0000-0002-2924-9040)). This search results page includes information about the author including their name, affiliation, and a link to their [ORCID profile](https://orcid.org/). It also includes a link to their [Dryad author profile page](https://datadryad.org/author/0000-0002-2924-9040).

A Dryad author profile page contains the collected works on Dryad for an author, with some special additional features. These include the citation information and a link to the primary journal article associated with each dataset, as well as a chart for each dataset showing the engagement metrics&mdash;views, downloads, and citations&mdash;over time.

#### Engagement metrics

View and download counts for Dryad datasets are collected using the [Make Data Count](https://makedatacount.org/) usage tracker, in association with DataCite. They are retrieved and displayed using [DataCite event data](https://support.datacite.org/docs/eventdata-guide). Citation counts and links for Dryad datasets are also provided via [DataCite](https://support.datacite.org/docs/data-citation).


## Saved searches

Dryad offers the ability to save searches to your account. This makes specific and complex searches easy to repeat. Saved searches can also be followed via email or web feed, giving you updates whenever a new Dryad publication meets your search criteria.

When you have set the query and filters you want to save on the [search results page](/search), click the <b><i class="fa fa-bookmark" aria-hidden="true" style="margin-right: .35ch;"></i>Save search</b> button that appears. You will be able to enter a title and description for your search. Saved searches can be managed and followed via email and web feed on the [saved searches page](/account/saved_searches) of your account.