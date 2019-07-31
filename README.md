# Hack Oregon 2019 Backend Docker - Django

|Build|Travis|DockerHub|
|-|-|-|
| Staging (Development) | [![Build Status](https://travis-ci.org/hackoregon/2019-backend-docker.svg?branch=staging)](https://travis-ci.org/hackoregon/2019-backend-docker) | [![](https://images.microbadger.com/badges/version/hackoregoncivic/backend-docker-django-dev.svg)](https://microbadger.com/images/hackoregoncivic/backend-docker-django-dev "Get your own version badge on microbadger.com") |
| Master (Production) | [![Build Status](https://travis-ci.org/hackoregon/2019-backend-docker.svg?branch=master)](https://travis-ci.org/hackoregon/2019-backend-docker) | [![](https://images.microbadger.com/badges/version/hackoregoncivic/backend-docker-django.svg)](https://microbadger.com/images/hackoregoncivic/backend-docker-django "Get your own version badge on microbadger.com") |

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
    volumes:
      - ./src_files
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


## About the `DEBUG` variable

This repo allows user to set a `DEBUG` variable to `true` or `false`

Following actions happen when variable is set to `true`:

* Disables push to ECS services from `master` branch
* ENV VARS are read from local .env (not Parameter Store)
* Sets Django App to Debug mode (See: [Django Docs](https://docs.djangoproject.com/en/2.2/ref/settings/#debug))
* Provides lower level logging, including SQL queries for troubleshooting

Following actions happen when variable is set to `false`:

* Allows push to ECS services from `master` branch
* If not in a Travis Build, will pull env vars from Parameter Store. (Travis will pull based on env vars set in Travis console)
* Django App DEBUG set to `False`
* Logging is restricted

## Gunicorn and WhiteNoise

This container uses Gunicorn as a Python WSGI HTTP Server for serving the API/data layer. A basic config file is included within this repo. It can import an additional `gunicorn_conf.py` file from your `local_settings` directory. (See: [Gunicorn Settings Docs](http://docs.gunicorn.org/en/latest/settings.html))

Instead of running an additional web server for static files, we are hosting our Swagger/static assets through the use of `WhiteNoise` whith in the same server. Read [this](http://whitenoise.evans.io/en/stable/#infrequently-asked-questions) for more info on why we are choosing this configuration

## PostgreSQL and Database router

Project will add the `apt.postgresql.org` to source.list and install a PostgreSQL 11.2 client within container, and performs a `wait-for` script to wait for database to connect before loading application.

Project will check for the `POSTGRES_NAME` variable to be set, otherwise will default to `sqlite3`

Project does contain POSTGIS support as well.

Additionally the Django Project contains a database router (router.py). This router allows project to connect to multiple databases. The database to connect to can then be set on a per model basis within your application using an "in_db" field.

For example, let's say you have a database split into partitions, and setup each partition as a separate database in your `local_settings/settings.py`:

```
DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'NAME': os.environ.get('POSTGRES_NAME'),
        'USER': os.environ.get('POSTGRES_USER'),
        'HOST': os.environ.get('POSTGRES_HOST'),
        'PORT': os.environ.get('POSTGRES_PORT')
    },
    'multnomah_county_permits': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'OPTIONS': {
                'options': '-c search_path=django,public,multnomah_county_permits'
            },
        'NAME': os.environ.get('POSTGRES_NAME'),
        'USER': os.environ.get('POSTGRES_USER'),
        'HOST': os.environ.get('POSTGRES_HOST'),
        'PORT': os.environ.get('POSTGRES_PORT')
    },
    'passenger_census': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'OPTIONS': {
                'options': '-c search_path=django,passenger_census'
            },
        'NAME': os.environ.get('POSTGRES_NAME'),
        'USER': os.environ.get('POSTGRES_USER'),
        'HOST': os.environ.get('POSTGRES_HOST'),
        'PORT': os.environ.get('POSTGRES_PORT')
    }
  }
  ```

You can then add the following to your `models.py`:

```
import django.db.models.options as options
options.DEFAULT_NAMES = options.DEFAULT_NAMES + ('in_db',)
```

And then specify a particular model uses a specific database:

```
class AnnualCensusBlockRidership(models.Model):
    year = models.IntegerField(blank=True, null=True)
    census_block = models.CharField(max_length=255, blank=True, null=True)
    total_ons = models.BigIntegerField(blank=True, null=True)
    stops = models.BigIntegerField(blank=True, null=True)
    geom_polygon_4326 = models.GeometryField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'annual_census_block_ridership'
        in_db = 'passenger_census'
```

## Development of the Docker IMAGE

This repo uses Travis for a CI/CD deployment of image to Docker Hub. Upon a merged pull request to the 'STAGING' branch, an image will be pushed to the `hackoregoncivic/backend-docker-django-dev` branch. This image can then be pulled for testing purposes with a live database.

When files are merged to `MASTER`, image will then de deployed to the `hackoregoncivic/backend-docker-django` repo. All Hack Oregon teams should use this repo for API development as well as production use.

Things to note:

* Deploy/Infra scripts should be housed in the `bin` folder
* The core Django files have been left relatively intact from generating a default project. This should allow for forward compatible code. Any updates/changes to the Django settings should be done in the `backend/hacko_settings.py` file, not the default settings.
* The `backend/settings.py`, `backend/urls.py`, and `gunicorn_conf.py` are each configured to import their respective files from a user's `local_settings` folder. If these do not exist, then they will be passed over silently. If you change/update these files during development for any reason, be sure to keep imports at the bottom of each file.

For example `backend/settings.py` imports the `hacko_settings`:

```
try:
    from backend.hacko_settings import *
except ImportError:
    pass

```

Then `hacko_settings` will import your `local_settings/settings` (assumes you have set the `src_files` volume in your docker_compose):

```
try:
    from src_files.local_settings.settings import *
except ImportError:
    pass
```
* Python requirements will be installed from the `requirements/common.txt`. We have been following pattern of >=current version, <next major version. This should allow robustness, and responsiveness to updates, within minimizing breaking changes. If we run into issues, we may want to pin to minor versions...
