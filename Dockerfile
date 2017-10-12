# Use the official Docker Hub Ubuntu latest LTS version base image
FROM ubuntu:16.04

LABEL maintainer "contact@ilyaglotov.com"

RUN apt-get update \
  \
  # Install main deps
  && apt-get -y install git \
                        libffi-dev \
                        libfontconfig \
                        python-dev \
                        python-pip \
                        python-psycopg2 \
                        software-properties-common \
                        \
  # Install Plaso
  && add-apt-repository ppa:gift/stable \
  && apt-get update \
  && apt-get -y install \
                plaso-tools \
                python-plaso \
                \
  # Clone latest timesketch repo
  && git clone --branch=master \
              --depth=1 \
              https://github.com/google/timesketch.git \
              /usr/local/src/timesketch \
              \
  # Install frontend deps: nodejs and yarn
  && apt-get install -y wget \
                        apt-transport-https \
                        \
  && wget -qO- https://deb.nodesource.com/setup_8.x | bash - \
  && wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y nodejs \
                        yarn \
                        \
  && cd /usr/local/src/timesketch \
  && yarn install \
  && yarn build \
  && yarn test \
  \
  # Install timesketch
  && pip install /usr/local/src/timesketch \
  \
  # Copy the Timesketch configuration file into /etc
  && cp /usr/local/share/timesketch/timesketch.conf /etc \
  && chmod 644 /etc/timesketch.conf \
  \
  # Clean up
  && apt-get purge -y apt-transport-https \
                      git \
                      nodejs \
                      wget \
                      yarn \
                      libfontconfig \
  && apt-get autoremove -y \
                      \
  && rm -rf /usr/local/src/timesketch/.git \
  && rm -rf /root/.cache \
  && rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Expose the port used by Timesketch
EXPOSE 5000

# Load the entrypoint script to be run later
ENTRYPOINT ["/docker-entrypoint.sh"]

# Invoke the entrypoint script
CMD ["timesketch"]
