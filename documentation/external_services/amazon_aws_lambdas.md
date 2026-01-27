Amazon AWS Lambdas
=====================================

We use lambda to validate uploaded files content
Currently we have the following scripts running on AWS Lambda:
- Frictionless
- Sensitive data detection

## Frictionless lambda

Frictionless lambda is used to validate data in uploaded files.

See more detail and the overview of the lambda implementation, instructions for installation and configuration in [here](../frictionless_integration/implementation_overview.md).

## Sensitive data lambda

Sensitive data detection lambda is used to detect sensitive data in uploaded files.
We check for the following sensitive information:
- SSN detection
- Physical address detection
- IP address detection
- Email address detection
- URL detection
- Endangered species detection

See mode details about setting up and configuring the lambda in [here](lambdas/sensitive_data_detection_lambda.md).
