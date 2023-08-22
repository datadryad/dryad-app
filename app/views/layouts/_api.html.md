# Dryad API

Dryad's REST API allows detailed interaction with Dryad contents. The most common case is to use GET requests to retrieve information about datasets, versions, and files.

Examples:

- [List datasets](/api/v2/datasets)
- [Get information about a dataset](/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7)
- [See versions of a dataset](/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/versions)
- [Get files from a version](/api/v2/versions/26724/files)
- [Download the most recent version of a dataset](api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/download)

Anonymous users of the API are limited to 30 requests per minute, with a lower limit for downloads of data files. When using the API, any DOI included must be <a href="https://www.w3schools.com/tags/ref_urlencode.ASP" target="blank">URL-encoded<span class="screen-reader-only"> (opens in new window)</a> to ensure correct processing.


## API accounts

To access more powerful features, an API account is required. API accounts allow users to:

- Access the API at higher rates (Authenticated users of the API are limited to 120 requests per minute)
- Access datasets that are not yet public, but are associated with the account's community (institution, journal, etc.)
- Update datasets associated with the account's community

See the <a href="https://github.com/CDL-Dryad/dryad-app/blob/main/documentation/apis/api_accounts.md" target="blank">API accounts github document<span class="screen-reader-only"> (opens in new window)</a> for more information on requesting an API account and using it to access datasets.


## Submission

The Submission API is used by systems that want to partner more closely with Dryad and create dataset submissions directly. The <a href="https://github.com/CDL-Dryad/dryad-app/blob/main/documentation/apis/submission.md" target="blank">API Submission Examples document<span class="screen-reader-only"> (opens in new window)</a> gives concrete examples of submission through the Dryad API.


## Dryad API methods

Detailed, interactive documentation of all available Dryad request methods:

<script src="/api/v2/docs/swagger-ui-bundle.js" charset="UTF-8"> </script>
<script src="/api/v2/docs/swagger-ui-standalone-preset.js" charset="UTF-8"> </script>
<script src="/api/v2/docs/swagger-initializer.js" charset="UTF-8"> </script>
<div id="swagger-ui"></div>
<script>
  window.onload = function() {
    const ui = SwaggerUIBundle({
      url: "/openapi.yml?3",
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
    document.querySelectorAll('.copy-to-clipboard').forEach(copyButton => {
      copyButton.addEventListener('click', e => {
        const pathButton = e.currentTarget.previousElementSibling
        const pathSpan = pathButton.querySelector('.opblock-summary-path')
        const requestUrl = pathSpan.dataset.path
        window.navigator.clipboard.writeText(apiUrl + requestUrl)
      })
    })
  })
</script>

<p style="text-align:right; font-size: smaller">Created with <a href="https://swagger.io/tools/swagger-ui/" target="blank">Swagger UI<span class="screen-reader-only"> (opens in new window)</a></p>
