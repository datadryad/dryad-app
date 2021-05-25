# Frictionless Integration

## Install frictionless
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
- Place the call for frictionless between backslashes, e.g.:
```ruby
result = `frictionless validate <tabular_file_path>`
```