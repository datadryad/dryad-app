# Updating the Lambda functions to use new versions of Python (& libraries)

We probably want to have a more managed process of updating lambdas, but the current minimal functions
follow the following procedure to create or update a lambda function.

1. If you're using more than the built-in Python libraries and boto (the Amazon AWS library), you'll need to get
   the extra libraries in somehow.  For a simply installing a small number of libraries people recommend using a Lambda 
   Layer.  We're using the basic gameplan outlined at this [LinkedIn article](https://www.linkedin.com/pulse/add-external-python-libraries-aws-lambda-using-layers-gabe-olokun/).
   Which creates the layer in AWS Cloudshell, zips it and uploads it to S3 for use as a layer.
2. Update and test code in the AWS UI console for the lambda function as needed. Also set up test
   events with JSON that gets passed into the lambda function if you want to 
   test it manually. The final Lambda code should also be saved to our repository. Most Lambdas so far are
   limited so it's only a few hundred lines of code for all of them and can be copied and pasted
   into the editor in the AWS console.
3. Ensure that the user has permission to invoke the Lambda from Dryad code using IAM.
4. Write code in the application that invokes the Lambda.  You can see examples of this with
   the `trigger_frictionless` method or the `trigger_excel_to_csv` in the generic_file.rb model.
5. The AWS Lambdas we have tend to be stateless and almost all information is passed
   in when invoked and results are passed back out to our own API upon completion. You can do things in
   Lambdas to make them "fatter" and with more access to other parts of the system like the database or
   S3 or other AWS services, but I preferred to keep them as simple as possible and pass results back to
   our API which is already in communication with databases and other resources rather than adding
   that shared resource and functionality directly to the Lambda. Most S3 access in lambdas is
   through pre-signed URLs that are passed in rather than sharing S3 access with the
   Lambda (but there may be an argument for doing that instead).

## Updating the Lambda Layer for Python libraries

Cloudshell was using Amazon Linux 2 and I had difficulty installing Python 3.11 because of it since
many default libraries were too old.

I also used the pyenv tool to install Python 3.11 since it works similarly to rbenv for Ruby which
I'm quite familiar with.

I used the following commands to install Python 3.11.6 prerequisites and create a virtual environment for it after
installing and configuring pyenv successfully. (If some of these are missing it may compile for 10 minutes
before telling you which dependency is missing or giving unhelpful error messages.) 

```bash
sudo yum install gcc make bzip2-devel ncurses-devel libffi-devel readline-devel openssl11 openssl11-devel sqlite-devel xz xz-devel
pyenv install 3.11.6
echo '3.11.6' > .python-version
```

You may want to log out of the shell or exit and `cd` back to the directory and pyenv should
automatically switch to the correct version of Python based on the .python_version file.

Check the version of python with `python --version` and it should be 3.11.6 if it all worked
correctly.

I used pyenv in place of venv in the instructions at the
[LinkedIn article above](https://www.linkedin.com/pulse/add-external-python-libraries-aws-lambda-using-layers-gabe-olokun/).

Then I did the pip installs like it mentioned for the following libraries (which also install
their dependencies). Use the directory structure and pip switches noted in the article so that
it zips up correctly for the Lambda Layer.

```
pandas
frictionless # the last 4.x version
frictionless[excel] # the last 4.x version
frictionless[csv] # the last 4.x version
frictionless[json] # the last 4.x version
requests
```

Zip it up, upload it to S3 and use it as a layer for the Lambda.

## Tips for updating the functions (what I did for the python 3.11.6 upgrade)
- Create new lambdas with slightly different names
- Add lambda layer
- Copy and paste code from old lambda to new lambda
- Copy and paste the test example events for future reference
- Look through all settings tabs to be sure settings are the same (except the newer python version)
- Update the Ruby code to call the lambdas with the new names
- Test and update IAM permissions as needed
- Test on your machine or dev machine to be sure it's working
- On the next deploy of the code it should also update to use the new lambdas in the new version

