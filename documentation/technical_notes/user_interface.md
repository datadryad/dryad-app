Dryad User Interface Technology
===============================

This document has some quick notes about the User Interface, but more complete
documentation is in the [User Interface README](../../stash/stash_engine/ui-library/README.md)

*Before editing any UI pieces*, please install the required dependencies as
 described in the README referenced above.

Viewing the demo:
- To see the demo pages on production, go to <https://datadryad.org/demo/>, or a
  similar page on other Dryad servers.
- To see the demo pages in your current branch, within the `stash_engine`
  directory, run `gulp`. then you can see the UI demo at `http://localhost:3000`
- If you run `gulp build`, the UI is recompiled and put in the regular rails directories

Structure of the code:
- Dryad's UI is part of stash_engine. Most files are in `stash/stash_engine/ui-library/scss`
- `main.scss` combines all of the other files
- The hierarchy is themes > objects > components > included files
