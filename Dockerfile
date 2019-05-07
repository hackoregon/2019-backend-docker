FROM python:3.7

MAINTAINER Brian H. Grant <bhgrant8@gmail.com>, "M. Edward (Ed) Borasky <ed.borasky@hackoregon.org>, "Nick Accuardi"
ENV PYTHONUNBUFFERED 1

# add required Debian packages
# https://docs.djangoproject.com/en/2.0/ref/contrib/gis/install/geolibs/
#
# set up PostgreSQL Global Development Group repository
COPY postgis-scripts/apt.postgresql.org.sh /src/
RUN chmod +x /src/apt.postgresql.org.sh && /src/apt.postgresql.org.sh
RUN apt-get update \
  && apt-get install -qqy --no-install-recommends \
    binutils \
    gdal-bin \
    libproj-dev \
    postgresql-client-11 \
  && apt-get clean

# create and populate /code
RUN mkdir /code
WORKDIR /code

#upgrade pip
RUN pip install --upgrade pip
RUN pip3 install --upgrade setuptools

COPY /requirements/* /code/
RUN pip install -r common.txt

RUN python
COPY manage.py /code/
COPY backend /code/backend

ENTRYPOINT [ "/code/bin/development-docker-entrypoint.sh" ]
