# Hack Oregon 2019 Backend Docker - Django

This repository contains the source files for the Docker Image for the 2019 Hack Oregon Season.

## What is Hack Oregon?

[Hack Oregon](http://www.hackoregon.org/) is a rapid prototyping lab taking a creative approach to
data projects that bring insight to complex issues in the public
interest. We’re a community-powered nonprofit, our teams are made of
volunteers, and all the work we do is open source.

## Features

* Provide a base Django Rest Framework Application using Python 3+/Django2+
* Include preconfiguration fo CORS headers and whitenoise for static asset hosting
* Provide support to connecting to a PostgreSQL 11 and PostGIS/GeoDjango
* Provide a Database Router for connecting to multiple DATABASES
* Provide a standardized method for maintaining/updating core Hack Oregon AgPWIGSec
* Published to Docker Hub through Travis CI/CD pipeline

## Getting Started

Hack Oregon Projects will make use of this image via the Dockerfile provided in the 2019-backend-cookiecutter-django repository and will generally not interact with this repo directly. Full setup steps will be in the mentioned repo.

### For uses outside of Hack Oregon:

This repo is intended to be a base image for Django Rest Framework APIs. It's intended to enforce certain conventions while allowing for individual project configuration. The image will work best when using a local Dockerfile as well as Docker-Compose:

1. Create your local Dockerfile. Here is an example to get you started:

```
FROM hackoregoncivic/backend-docker-django-dev
ENV PYTHONUNBUFFERED 1

## Moves into main directory of image
WORKDIR /code

## copy your local requirements
COPY requirements.txt /code/

## copy your django settings overrides and url overrides
COPY local_settings /code/local_settings/

## install requirments
RUN pip install -r requirements.txt
RUN python

## copy entrypoint and any other startup files
COPY bin /code/bin/

## give execution perms on manage.py/other python files
RUN chmod +x *.py

## run your entrypoint file
ENTRYPOINT [ "/code/bin/development-docker-entrypoi
```

2. Create a .env file in root folder to pass in environment variables.  

Example:
```
DEBUG=true
POSTGRES_USER=transportation-systems
POSTGRES_NAME=transportation-systems-main
POSTGRES_HOST=54.202.102.40
POSTGRES_PASSWORD=Z6mHewT5He75
DJANGO_SECRET_KEY=h0ldon2th3nighT
```

3.
