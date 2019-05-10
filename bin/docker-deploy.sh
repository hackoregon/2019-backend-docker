#! /bin/bash

# Tag, Push and Deploy only if it's not a pull request
if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ]; then

    # Push only if we're testing the master branch
    if [ "$TRAVIS_BRANCH" == "master" ]; then
      docker tag  hackoregoncivic/backend-docker-django-dev hackoregoncivic/backend-docker-django
      docker push hackoregoncivic/backend-docker-django
    elif [ "$TRAVIS_BRANCH" == "staging" ]; then
      docker push hackoregoncivic/backend-docker-django-dev
    else
      echo "Skipping deploy because branch is not master or test-deploy branch"
    fi
else
  echo "Skipping deploy because it's a pull request"
fi
