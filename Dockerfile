# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG JUPYTERHUB_VERSION
FROM jupyterhub/jupyterhub-onbuild:$JUPYTERHUB_VERSION

# Update and install some package
RUN apt-get update && apt-get install -yq --no-install-recommends \
	zsh \
	vim \
	git \
	libcurl4-openssl-dev \
    libmemcached-dev \
    libsqlite3-dev \
    libzmq3-dev \
    make \
    nodejs \
    npm \
    pandoc \
    sqlite3 \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && hash -r

# Install dockerspawner, oauth, postgres
RUN conda update -n base conda && \
    /opt/conda/bin/conda install -y psycopg2=2.7 && \
    /opt/conda/bin/conda clean -tipsy && \
    /opt/conda/bin/pip install --no-cache-dir \
        oauthenticator==0.7.* \
        dockerspawner==0.9.*

# Copy TLS certificate and key
ENV SSL_CERT /srv/jupyterhub/secrets/jupyterhub.crt
ENV SSL_KEY /srv/jupyterhub/secrets/jupyterhub.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /srv/jupyterhub/secrets && \
    chmod 600 /srv/jupyterhub/secrets/*

COPY ./userlist /srv/jupyterhub/userlist

# Install nbviewer

ENV NBVIEWER_THREADS 2

WORKDIR /srv

RUN git clone https://github.com/jupyter/nbviewer.git

WORKDIR /srv/nbviewer

# asset toolchain
RUN npm install .

# python requirements
RUN /opt/conda/bin/conda install -y -c conda-forge elasticsearch \
		jupyter_client \
		markdown \
		newrelic!=2.80.0.60 \
		nbformat>=4.2 \
		nbconvert>=5.2.1 \
		ipython \
		pycurl \
		pylibmc \
		tornado \
		statsd \
		invoke

# RUN invoke bower
WORKDIR /srv/nbviewer/nbviewer/static

RUN ../../node_modules/.bin/bower install \
  --allow-root \
  --config.interactive=false

WORKDIR /srv/nbviewer

# build css
RUN invoke less

RUN export PATH=/srv/nbviewer:$PATH

#WORKDIR /srv/jupyterhub
