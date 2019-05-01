FROM python:3
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
#upgrade pip
COPY /requirements/common.txt /code/
RUN pip install -r common.txt
COPY . /code/
