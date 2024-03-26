
Amazon AWS SES email
=====================

Email is handled through Amazon's SES service. Setup is mostly managed within the AWS console.

A set of SMTP credentials were generated for SES, and these credentials are
imported into Rails via the environment configuration files in
`conf/environments`. Once an environment is loaded and connected to the SES SMTP
server, all of the other email functionality follows normal Rails behaviors.

