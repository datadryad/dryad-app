# Frictionless Implementation Overview

## Background
1. Frictionless is a Python library that runs in an AWS Lambda function.  You can also run it locally for
   and manually to see the output of validation, but it doesn't work with our code this way.  Our 
   current code for the lambda is at `script/py-frictionless/lambda.py`.
2. The AWS lambda takes these parameters `download_url, token, callback_url` in the event being passed in.
3. Once AWS lambda has finished validating it calls the callback_url (our API) with the API token that
   authorizes the call.

The results of the validation are stored in the `stash_engine_frictionless_reports` table which is associated with a
specific file that was validated.

The AWS Lambda was put into the AWS console and uses a Lambda Layer (Python version and libraries that include the 
frictionless ones)
created under the AWS cloudshell.  I believe I followed
[this article](https://www.linkedin.com/pulse/add-external-python-libraries-aws-lambda-using-layers-gabe-olokun/).

In order to use the lambda from a development environment you need to either:

- Use an environment that connects to our development database server (`rails server -e local_dev`)

OR

- Create a Rails environment for your server with correctly set server domain name information in the environment
  configuration file.  The server needs to be accessible on the internet so that the Lambda can access the
  callback URL of the server's API to update the results of the frictionless validation.

## Additional info

- **The JSON output for validation is saved in a database field** which we refer to later.
  The JSON has information about number or errors and all error messages.
- At the appropriate time, a **React component is initialized and displayed** by the user.
  It is from [frictionlessdata/components](https://github.com/frictionlessdata/components).
  See [the code for initializing and displaying it](https://github.com/CDL-Dryad/dryad-app/blob/f61b26e21f5d62fef7293de2a5a756fa5ab1fbc8/app/javascript/components/FileUpload/ModalValidationReport/ModalValidationReport.js).
  - Imports on line 6 & 7 would be set for the generic frictionless component
    starting with `@frictionlessdata/frictionless-components` instead of ours for a new implementation.
    Also install this component into your `package.json` for dependency management
    with npm or yarn before using.
  - Our example initializes the component (lines 12-13) and renders it inside the
    `<div>` with ID `validation_report` (lines 43-44).
  - We are using a slightly customized component in order to address accessibility and
    product requirements. We ended up forking [frictionlessdata/components](https://github.com/frictionlessdata/components),
    making changes and publishing our modified version to npm so we could use npm/yarn
    dependency management like with the rest of the library dependencies.
  