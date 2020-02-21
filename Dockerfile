# Use the official Docker Hub Ubuntu latest LTS version base image
FROM ubuntu:18.04
LABEL maintainer "contact@ilyaglotov.com"

ARG COMMIT_TAG=20191220

RUN apt-get update \
  \
  # Install main deps
  && apt-get -y install git \
                        libffi-dev \
                        libfontconfig \
                        python3-dev \
                        python3-pip \
                        python3-psycopg2 \
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
  && git clone --branch=$COMMIT_TAG \
               --depth=1 \
               https://github.com/google/timesketch.git \
               /usr/local/src/timesketch \
               \
  # Install timesketch
  && pip3 install /usr/local/src/timesketch \
  \
  # Copy the Timesketch configuration file into /etc
  && mkdir /etc/timesketch \
  && cp /usr/local/src/timesketch/data/timesketch.conf /etc/timesketch/ \
  && chmod 644 /etc/timesketch/timesketch.conf \
  \
  # Clean up
  && apt-get purge -y apt-transport-https \
                      git \
                      wget \
                      libfontconfig \
  && apt-get autoremove -y \
                           \
  && rm -rf /usr/local/src/timesketch/.git \
            /root/.cache \
            /var/lib/apt/lists/*

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Expose the port used by Timesketch
EXPOSE 5000

# Load the entrypoint script to be run later
ENTRYPOINT ["/docker-entrypoint.sh"]

# Invoke the entrypoint script
CMD ["timesketch"]
