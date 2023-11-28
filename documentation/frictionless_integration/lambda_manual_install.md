# Installing updates to the Lambda functions

We probably want to configure lambdas in a more formal way, but currently we are:

1. Creating a Lambda layer to contain the python libraries needed for non-built-ins in python or boto.
  - To do that I used the instructions at https://www.linkedin.com/pulse/add-external-python-libraries-aws-lambda-using-layers-gabe-olokun/ 
  - I had difficulty getting python 3.11.6 to install so I used pyenv to install it.  However it required
    installing these libraries through yum for Amazon linux 2 in cloudshell:
    `gcc make bzip2-devel ncurses-devel libffi-devel readline-devel openssl11 openssl11-devel sqlite-devel xz xz-devel`
  - After getting pyenv installed and configured, do `pyenv install 3.11.6` and add a .python-version file
    to make it switch automatically to that version when you cd into the directory.
  - Follow the instructions from the linkedin article to create the layer.
2. 
