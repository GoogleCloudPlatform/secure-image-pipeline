
# Base CentOS 7 with a few perks
# Includes epel repo for local build

FROM gcr.io/gcp-runtimes/centos7




# Non-root user for security purposes.
#
# UIDs below 10,000 are a security risk, as a container breakout could result
# in the container being ran as a more privileged user on the host kernel with
# the same UID.
#
# Static GID/UID is also useful for chown'ing files outside the container where
# such a user does not exist.
RUN groupadd  nonroot -g 10001  && useradd -u 10000 -g nonroot -d /home/nonroot nonroot

RUN yum update -y && yum clean all

# Use the non-root user to run our application
USER nonroot

# Default arguments for your app (remove if you have none):
CMD ["bash"]