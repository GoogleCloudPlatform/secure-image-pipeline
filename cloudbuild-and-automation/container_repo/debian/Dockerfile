# Pull base image.
FROM debian:stable-slim

ARG DEBIAN_FRONTEND=noninteractive

# Non-root user for security purposes.
#
# UIDs below 10,000 are a security risk, as a container breakout could result
# in the container being ran as a more privileged user on the host kernel with
# the same UID.
#
# Static GID/UID is also useful for chown'ing files outside the container where
# such a user does not exist.
RUN groupadd -r -g 10001 nonroot &&\
    useradd -r -g nonroot -d /home/nonroot -s /sbin/nologin -c "Docker image user" nonroot
    
# Packaging.
#
# Install relevant software etc.
# RUN \
#   sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
#   apt-get update && \
#   apt-get -y upgrade && \
#   apt-get install -y build-essential && \
#   apt-get install -y software-properties-common && \
#   apt-get install -y byobu curl git htop man unzip vim wget && \
#   rm -rf /var/lib/apt/lists/*

# Add files.
# ADD root/.bashrc /root/.bashrc
# ADD root/.gitconfig /root/.gitconfig
# ADD root/.scripts /root/.scripts

# Set environment variables.
ENV HOME /home/nonroot

# Define working directory.
WORKDIR $HOME

# Change to nonroot user.
USER nonroot

# Define default command.
CMD ["bash"]