# Hack Oregon 2019 Backend Docker - Django

This repository contains the source files for the Docker Image for the 2019 Hack Oregon Season.

## What is Hack Oregon?

[Hack Oregon](http://www.hackoregon.org/) is a rapid prototyping lab taking a creative approach to
data projects that bring insight to complex issues in the public
interest. We’re a community-powered nonprofit, our teams are made of
volunteers, and all the work we do is open source.

## Features

* Provide a base Django Rest Framework Application using Python 3+/Django2+
* Include pre-configuration for CORS headers and whitenoise for static asset hosting
* Provide support to connecting to a PostgreSQL 11 and PostGIS/GeoDjango
* Provide a Database Router for connecting to multiple DATABASES
* Provide a standardized method for maintaining/updating core Hack Oregon dependencies/settings
* Published to Docker Hub through Travis CI/CD pipeline
* Gunicorn server with configuration file
* 2 stage deploys:
  - `staging` branch deploys to the `hackoregoncivic/backend-docker-django-dev` Dockerhub repo.
  - `master` branch deploys to the `hackoregoncivic/backend-docker-django` Dockerhub repo.

## Getting Started

Hack Oregon Projects will make use of this image via the Dockerfile provided in the [2019-backend-cookiecutter-django](https://github.com/hackoregon/2019-backend-cookiecutter-django) repository and will generally not interact with this repo directly. Full setup steps will be in the mentioned repo.

### For uses outside of Hack Oregon:

This repo is intended to be a base image for Django Rest Framework APIs. It's intended to enforce certain conventions while allowing for individual project configuration. The image will work best when using a local Dockerfile as well as Docker-Compose:

1. Create your local Dockerfile. Here is an example to get you started:

```
## Add -dev to dockername to pull from development repo
FROM hackoregoncivic/backend-docker-django
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
ENTRYPOINT [ "/code/bin/docker-entrypoint.sh" ]
```

2. Create a .env file in root folder to pass in environment variables.  If you add the Postgres related vars, app will use postgres, otherwise defaults to sqlite3.

Example:
```
DEBUG=true
POSTGRES_USER=transportation-systems
POSTGRES_NAME=transportation-systems-main
POSTGRES_HOST=54.202.102.40
POSTGRES_PASSWORD=Z6mHewT5He75
DJANGO_SECRET_KEY=h0ldon2th3nighT
```

3. Create a local_settings folder which will contain 3 files: `settings.py`, `urls.py`, and `gunicorn_conf.py`. These files will include any Django settings for your project, that you need to override from the default, as well as your url routes, and [gunicorn webserver configuration](http://docs.gunicorn.org/en/stable/settings.html#settings) respectively. If you are just spinning up the default hello world django project, and not adding any additional url routes, omit the `urls.py` or a blank file will cause errors.

For example, if you are working to create a local django app named `passenger_census` you would like to import, you can include you updated `INSTALLED_APPS` object in the `local_settings/settings.py` and it will be imported.

```
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'django_filters',
    'rest_framework',
    'rest_framework_gis',
    'rest_framework_swagger',
    'passenger_census'
]
```

And an example `urls.py`, which creates a swagger view and route for urls in package:

```
"""backend URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/2.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.conf.urls import url, include
from django.urls import path
from rest_framework.routers import DefaultRouter

from rest_framework_swagger.views import get_swagger_view


schema_view = get_swagger_view(title='Hack Oregon 2018 Transportation Systems APIs')

urlpatterns = [
    url(r'^transportation-systems/$', schema_view),
    url(r'^transportation-systems/passenger-census/', include('hackoregon_transportation_systems.passenger_census.urls')),
]
```

4. Create a requirements file for any pip requirements. Using the above Dockerfile, this would be in your project root folder, and named `requirements.txt`.

5. Create a Docker Compose file to configure the Docker stack for starting up. If you are connecting to an external database, you should just need to configure the api container.

Here is example file to get you started:

```
version: '3.4'
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    image: api
    command: ./bin/docker-entrypoint.sh
    ports:
      - "8000:8000"
    environment:
      - PROJECT_NAME=${PROJECT_NAME}
      - DEBUG=True
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_NAME=${POSTGRES_NAME}
      - POSTGRES_HOST=${POSTGRES_HOST}
      - POSTGRES_PORT=${POSTGRES_PORT}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
```
This will spin up a local docker image named `api`, which builds based on the provided Dockerfile, passing in the environmental variables from your .env file, and startup based on a `docker-entrypoint.sh` script.

6. Create a bin folder, to house a `docker-entrypoint.sh` and any other startup files.

7. Within bin folder, create a `docker-entrypoint.sh` file to run startup script.

Example (Please note that copy and pasting from Dockerhub may cause some of the special characters in this example to become url-encoded, which may cause issues when attempting to run. Double check the file if you run into errors.):

```
#! /bin/bash

# wait-for-postgres.sh
# https://docs.docker.com/compose/startup-order/

# http://linuxcommand.org/lc3_man_pages/seth.html:
# -e  Exit immediately if a command exits with a non-zero status.
set -e

if [ "$POSTGRES_NAME" ]; then
  export PGPASSWORD=$POSTGRES_PASSWORD
  until psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -p "$POSTGRES_PORT" -d postgres -c '\q'
  do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 5
  done
fi

>&2 echo "Postgres is up"
echo Debug: $DEBUG
chmod +x *.py

echo "Make migrations"
python -Wall manage.py makemigrations

echo "Migrate"
python -Wall manage.py migrate

# Collect static files
echo "Collect static files"
python -Wall manage.py collectstatic --noinput

echo "Run server..."
python -Wall manage.py runserver 0.0.0.0:8000
```

8. With this setup, you should be ready to startup an app.

First you can build your application:

```
$ docker-compose build
```

Then start your application:

```
$ docker-compose up
```


## CI/CD with Travis
