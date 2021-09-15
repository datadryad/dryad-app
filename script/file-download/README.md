# Download.rb
Downloads the latest submitted files from a dataset from the API.

## Before running
- Be sure ruby (2.6.6 default) is installed
- `bundle install`
- Fill in the section toward the top of the script around lines 27-30 with needed
  information.
  - *base_url* -- what server you're using
  - *api_key* -- this should've been given to you if you want more than public access
  - *api_secret* -- this should've been given to you if you want more than public access
  - *base_path* -- the absolute path of the directory to save downloaded files in.
    By default, it saves inside directories inside the script directory.  Change to
    somewhere else if you wish.

## How to run

```shell
./download.rb <landing url or doi:xxxxxxx/xxxxxx>
# Or
ruby download.rb <landing url or doi:xxxxxxx/xxxxxx>
```

You should see it use the API to download the latest submitted versions of files
for a dataset.  You'll see it saving files and progress bars for each file.

When it is done, you should be able to find the files under your *base_path*
directory and named based on the DOI.

Examples (from dev environment):

```shell
./download.rb https://dryad-dev.cdlib.org/stash/dataset/doi:10.7959/dryad.mkkwh740
./download.rb doi:10.5061/dryad.tt52v
./download.rb doi:10.5072/FK23X8C96D
```