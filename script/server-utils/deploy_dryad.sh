#!/usr/bin/bash
#
# Run capistrano locally to redeploy Dryad UI application
#

function errexit {
    >&2 echo $*
    >&2 echo "Arg for git reference (branch or tag) required"
    exit 1
}

# Arg for git reference (branch or tag) required
if [ $# -ne 1 ]; then errexit "Usage: $(basename $0) <git-ref>"; fi


WORKING_TREE=/home/ec2-user/dryad-app
CAP_STAGE="v3_stage"
DEPLOY_TO="/home/ec2-user/deploy"
RAILS_ENV="v3_stage"
REPO_URL="https://github.com/CDL-Dryad/dryad-app.git"
BUNDLE="/home/ec2-user/.rbenv/shims/bundle"
BRANCH=$1

cd $WORKING_TREE
git pull origin $BRANCH
$BUNDLE config set --local path '.'
$BUNDLE config set --local without 'pgsql'
$BUNDLE config set --local clean 'true'
$BUNDLE install
echo $BUNDLE exec cap --trace $CAP_STAGE deploy BRANCH=$BRANCH REPO_URL=$REPO_URL RAILS_ENV=$RAILS_ENV DEPLOY_TO=$DEPLOY_TO SERVER_HOSTS='localhost'
$BUNDLE exec cap --trace $CAP_STAGE deploy BRANCH=$BRANCH REPO_URL=$REPO_URL RAILS_ENV=$RAILS_ENV DEPLOY_TO=$DEPLOY_TO SERVER_HOSTS='localhost'
