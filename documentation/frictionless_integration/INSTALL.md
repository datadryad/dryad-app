# Frictionless Integration

For the frictionless integration, you'll need both the Frictionless
Python and library and also to work with the `components` React/Typescript
library which is forked from `frictionlessdata/components`.

## Install Frictionless Python Requirements
(Instructions for Debian GNU/Linux like)

- Prerequisites:
  - Python 3.7+
  - python-pip
    
### System wide installation
1. Install frictionless framework
```bash
$ pip install frictionless
```

Obs.: it's common to have Python 2 and Python 3 installed in the same system.
In this case, it's possible that you have to use `pip3` instead of `pip` in the
command above.

### Project level installation
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

4. Install frictionless framework
```bash
$ pip install frictionless
```

### Run frictionless from inside ruby/rails code
- Place the call for frictionless between backticks, e.g.:
```ruby
result = `frictionless validate <tabular_file_path>`
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

The page at `https://github.com/CDL-Dryad/components/blob/dev/docs/dev_workflow.md` gives
additional information on how to work with the frictionless UI components.



