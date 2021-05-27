
Login Process
================

Dryad login is managed by ORCID. Only the `production` Rails environment uses the real
ORCID system; all other environments use the ORCID sandbox system.

Bypassing Login
===============

To bypass login, set the environment variable `TEST_LOGIN` before starting
Rails. You must run Rails in an environment other than `production`. Then, on
the login page, there will be a link to "Use test login".

To bypass a tenant's Shibbleth login, see the [tenant documentation](tenant.md).

