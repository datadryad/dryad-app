# Download.rb
Downloads the latest submitted files from a dataset from the API.

## Before running
- Be sure ruby (2.6.6 default) is installed if in Windows you may need mingw option.
  Go to https://rubyinstaller.org/downloads/ and install Ruby+Devkit 2.6.8-1 (x64)
- `bundle install` inside this directory.
- It now reads config from `C:\DryadData\api_config.yml` (Windows special) or `~/.api_config.yml`
- If it's not set, it prompts you what to put in that file for API access.

## How to run

```shell
./download.rb
# Or
ruby download.rb
```

It asks you for the doi or landing page URL to download.

You should see it use the API to download the latest submitted versions of files
for a dataset.  You'll see it saving files and progress bars for each file.

When it is done, it tells you where the files are located.

