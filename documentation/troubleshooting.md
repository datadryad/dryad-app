Troubleshooting
==================

Some common problems and how to deal with them.

Also see the notes on
[handling failed submissions](https://confluence.ucop.edu/display/Stash/Dryad+Operations#DryadOperations-FixingaFailedSubmission).


Merrit async download check
===========================

This error typically means that the account being used by the Dryad UI
to access Merritt does not have permisisons for the object being
requested. This is often because either the Dryad UI or the object in
Merritt is using a UC-based account, while the other is using a non-UC account.
