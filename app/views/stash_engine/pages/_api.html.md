# Dryad API

Dryad's REST API allows detailed interaction and programmatic interfacing with Dryad contents. The most common case is to use GET requests to retrieve information about datasets, versions, and files.

Examples:

- [List datasets](https://datadryad.org/api/v2/datasets)
- [Search for datasets](https://datadryad.org/api/v2/search?q=carbon)
- [Get information about a dataset](https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7)
- [See versions of a dataset](https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/versions)
- [Get files from a version](https://datadryad.org/api/v2/versions/26724/files)
- [Download the most recent version of a dataset](https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/download)

When using the API, any DOI included must be <a href="https://www.w3schools.com/tags/ref_urlencode.ASP" target="blank">URL-encoded<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a> to ensure correct processing. Anonymous users of the API are limited to 30 requests per minute, with a lower limit for downloads of data files.


## Detailed documentation

- Basic REST API (see below)
- [Search API](https://github.com/datadryad/dryad-app/blob/main/documentation/apis/search.md)
- [Submission API](https://github.com/datadryad/dryad-app/blob/main/documentation/apis/submission.md)

## API accounts

To access more powerful features, an API account is required. API accounts allow users to:

- Access the API at higher rates (authenticated users may make up to 120 requests per minute)
- Access datasets that are not yet public, but are associated with the account's community (institution, journal, etc.)
- Update datasets associated with the account's community

See the <a href="https://github.com/datadryad/dryad-app/blob/main/documentation/apis/api_accounts.md" target="blank">API accounts document<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a> for more information on requesting an API account and using it to access datasets.


## Submission

The Submission API is used by institutions that partner closely with Dryad, and use systems to create dataset submissions directly. Please contact us if you are [interested in partnering with Dryad](/contact#get-involved), and setting up an API account for submission.

The <a href="https://github.com/datadryad/dryad-app/blob/main/documentation/apis/submission.md" target="blank">API submission examples document<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a> gives concrete examples of submission through the Dryad API.

### Dryad sandbox

<a href="https://sandbox.datadryad.org/" target="blank">Dryad's sandbox server<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a> allows users to experiment with data submission and the Dryad API, without worrying about the effects on "real" data. Anyone may create an account on the sandbox server for testing purposes. When creating an account, keep in mind that Dryad's sandbox relies on the <a href="https://sandbox.orcid.org/" target="_blank">sandbox version of ORCID<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a>, which allows you to make test ORCID accounts. Sandbox ORCID IDs should be used in the Dryad sandbox, while use of Dryad's production system requires a real ORCID ID.


## Dryad API methods

Detailed, interactive documentation of all available Dryad request methods:

<script src="/api/v2/docs/swagger-ui-bundle.js" charset="UTF-8"> </script>
<script src="/api/v2/docs/swagger-ui-standalone-preset.js" charset="UTF-8"> </script>
<script src="/api/v2/docs/swagger-initializer.js" charset="UTF-8"> </script>
<div id="swagger-ui"></div>
<script>
  function copyUrl(e) {
    const copyButton = e.currentTarget.firstElementChild;
    const pathSpan = e.currentTarget.parentElement.querySelector('.opblock-summary-path')
    const requestUrl = pathSpan.dataset.path
    navigator.clipboard.writeText(`${apiUrl}${requestUrl}`).then(() => {
      // Successful copy
      copyButton.parentElement.setAttribute('title', 'Copied');
      copyButton.classList.remove('fa-paste');
      copyButton.classList.add('fa-check');
      copyButton.innerHTML = '<span class="screen-reader-only">Copied</span>'
      setTimeout(function(){
        copyButton.parentElement.setAttribute('title', 'Copy API URL');
        copyButton.classList.add('fa-paste');
        copyButton.classList.remove('fa-check');
        copyButton.innerHTML = '';
      }, 2000);
    });
  }
  window.onload = function() {
    const ui = SwaggerUIBundle({
      url: "/openapi.yml?5",
      dom_id: '#swagger-ui',
      deepLinking: true,
      presets: [
        SwaggerUIBundle.presets.apis,
        SwaggerUIStandalonePreset
      ],
      plugins: [
        SwaggerUIBundle.plugins.DownloadUrl
      ],
      supportedSubmitMethods: ['get'],
      defaultModelsExpandDepth: 0,
    })
    window.ui = ui
  }
  let apiUrl = ''
  awaitSelector('.servers select').then((server) => {
    apiUrl = server.value
    server.addEventListener('change', e => {
      apiUrl = e.currentTarget.value
    })
    document.querySelectorAll('.opblock-summary').forEach(block => {
      const newEl = document.createElement("div");
      newEl.setAttribute('class', 'copy-icon');
      newEl.setAttribute('role', 'button');
      newEl.setAttribute('tabindex', 0);
      newEl.setAttribute('aria-label', 'Copy API URL');
      newEl.setAttribute('title', 'Copy API URL');
      newEl.innerHTML = '<i class="fa fa-paste" role="status"></i>';
      block.insertBefore(newEl, block.lastElementChild);
      newEl.addEventListener('click', copyUrl)
      newEl.addEventListener('keydown', (e) => {
        if (event.key === ' ' || event.key === 'Enter') {
          copyUrl(e)
        }
      });
    })
  })
  awaitSelector('.opblock.is-open').then((el) => el.scrollIntoView())
</script>

<p style="text-align:right; font-size: smaller">Created with <a href="https://swagger.io/tools/swagger-ui/" target="blank">Swagger UI<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a></p>
