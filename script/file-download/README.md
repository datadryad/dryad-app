Download.rb
============

Downloads the latest submitted files from a dataset from the API.

Before running
---------------

- Be sure ruby (2.6.6 default) is installed if in Windows you may need mingw option.
  Go to https://rubyinstaller.org/downloads/ and install Ruby+Devkit 2.6.8-1 (x64)
- `bundle install` inside this directory.
- It now reads config from `C:\DryadData\api_config.yml` (Windows special) or `~/.api_config.yml`
- If it's not set, it prompts you what to put in that file for API access.

How to run
----------

```shell
./download.rb
# Or
ruby download.rb
```

It asks you for the doi or landing page URL to download.

You should see it use the API to download the latest submitted versions of files
for a dataset.  You'll see it saving files and progress bars for each file.

When it is done, it tells you where the files are located.


For Mac users
-------------

Install Xcode (for building ruby gems)

```
# Xcode command line tools
xcode-select --install
# Accept license if needed
sudo xcodebuild -license accept
```

Recommended that you install brew (https://docs.brew.sh/Installation)

Update bundle with
```
sudo gem install bundler:2.3.22
```

Provide format for .yml file

Suggestion to add an alias to zsh with
```
#replace $scriptdir with the full path, such as /Users/ash/home/dryad-file-download/script/file-download
touch ~/.zshrc
echo 'alias dryad_dl=“ruby $scriptdir/download.rb” >> ~/.zshrc
source ~/.zshrc
```

It is recommended that you also modify .zprofile:

```
touch ~/.zprofile
nano ~/.zprofile
#Add these lines to .zprofile:
#sources a zshrc file, if it exists. This loads the contents on login shells. N$
if [ -f ~/.zshrc ]; then
  . ~/.zshrc
fi
#Save the buffer with ctrl+x and hit enter to keep the filename
```

It may be necessary to give executable permissions to a file with:
```
chmod +x [filename]
```
