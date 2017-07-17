# Use the official Docker Hub Ubuntu latest LTS version base image
FROM ubuntu:16.04

# Install Timesketch dependencies
RUN apt-get update \
  && apt-get -y install python-pip \
                        python-dev \
                        libffi-dev \
                        python-psycopg2 \
                        software-properties-common \
                        git

# Install Plaso
RUN add-apt-repository ppa:gift/stable \
  && apt-get update \
  && apt-get -y install \
    python-plaso \
  && rm -rf /var/lib/apt/lists/*

# Use pip to install Timesketch
RUN git clone --branch=master \
              --depth=1 \
              https://github.com/google/timesketch.git \
              /tmp/timesketch \
  && rm -rf /tmp/timesketch/.git \
  && apt-get purge -y git

RUN pip install /tmp/timesketch

# Copy the Timesketch configuration file into /etc
RUN cp /usr/local/share/timesketch/timesketch.conf /etc
RUN chmod 644 /etc/timesketch.conf

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Expose the port used by Timesketch
EXPOSE 5000

# Load the entrypoint script to be run later
ENTRYPOINT ["/docker-entrypoint.sh"]

# Invoke the entrypoint script
CMD ["timesketch"]
