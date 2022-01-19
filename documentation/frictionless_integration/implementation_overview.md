# Frictionless Implementation Overview

## Background
1. Our Frictionless [install](./INSTALL.md) is for the Python libraries which are called from a Python command
   line and return validation results as standard output which is captured by our application.
   While Frictionless had a validation server being written, it wasn't ready when we worked on this project.
2. We capture the standard output of the validation and save it to our database.
3. From the validation output, we display a React component which is a lightly modified version
   of [frictionlessdata/components](https://github.com/frictionlessdata/components).

## Code Examples
- **Calling validation and capturing validation output.**  See the
  [call_frictionless](https://github.com/CDL-Dryad/dryad-app/blob/7299fff7dd5e2e2ea578c7caf5c3753a3c6d91f1/stash/stash_engine/app/models/stash_engine/generic_file.rb#L233)
  method in our github repository.  Note, the `$(pyenv init -)` is specific to the way we installed
  frictionless on our servers with pyenv.  See, also our 
  [config](https://github.com/CDL-Dryad/dryad-app/blob/c5a4c1241cab1495ade69081300faf8441dd649f/config/app_config.yml#L171) 
  for values being interpolated in the call to frictionless.
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
  