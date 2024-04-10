# Frictionless Integration Install

# NOTE: this document is deprecated, but it may be useful to install a local copy of the frictionless python libraries for other kinds of testing

Some of these install instructions are specific to our installation.
[We've also documented an overview of how we integrated Frictionless](./implementation_overview.md).

For the frictionless integration, you'll need both the Frictionless
Python and library and also to work with the `components` React/Typescript
library which is forked from `frictionlessdata/components`.

## Install Frictionless Python Requirements
(Instructions for Debian GNU/Linux like)

- Prerequisites:
  - Python 3.7+
  - python-pip
    
### System wide installation
Install python3 and pip for python version 3 according to your preferred way such as system package manager.
1. Install frictionless framework (general and for the tabular files Dryad wish to analyse)
- For the last update of this document, there are 4 types: csv, xls, xlsx, json.
```bash
# note for below, pip for python version 3 might be pip3 and python3
# depending on the server setup where pip and python might be for python2 instead
$ pip install frictionless
$ pip install frictionless[excel]
$ pip install frictionless[json]
```
2. Upgrading
```bash
$ pip install frictionless --upgrade
```

### Project level installation and upgrading
You can create a virtual environment to wrap a specific python environment for the project.
(Note: on our servers we are using pyenv and some annoying hacks to get it working
within the systemd setup.)

1. Install virtualenv
```bash
$ sudo apt install python3-virtualenv 
```
2. Create virtualenv
```bash
$ virtualenv [-p <python3_path>] <env_dir>
```

3. Activate virtualenv
```bash
$ <env_dir>/bin/activate
```

4. Install frictionless framework plugins for all the tabular packages that you want to validate.
- See a list of all the types on https://framework.frictionlessdata.io > Tutorials > Formats Tutorials
```bash
$ pip install frictionless
$ pip install frictionless[excel]
$ pip install frictionless[json]
```

5. Upgrade frictionless package
```bash
$ pip install frictionless --upgrade
```

### Run frictionless from inside ruby/rails code
- Place the call for frictionless between backticks, e.g.:
```ruby
result = `frictionless validate --path <tabular_file_path>`
```
However note, that additional code has been added (for production) to
1. Be sure pyenv has loaded correctly
2. Redirect any errors returned by python or frictionless to stdout so
we'll see and log them from our Rails app.
   
## Frictionless UI component library

Our fork of the frictionless React/Typescript library is at
`git@github.com:CDL-Dryad/components.git`.  Be sure to clone it into
your own directory to begin modifying it.

Our npmjs.com organization is called `cdl-dryad` which I hope allows all
developers to work with and publish the component we use.

The page at `https://github.com/CDL-Dryad/components/blob/main/docs/dev_workflow.md` gives
additional information on how to work with the frictionless UI components.



