FROM debian:stretch
# Build
ARG MIRROR_DEBIAN
ARG PYPI_URL
ARG PYPI_HOST
ARG RUBY_URL
# Run
ENV DEBIAN_FRONTEND noninteractive

COPY ./config/ /config
COPY requirements.txt /opt/requirements.txt
COPY build.sh /opt/build.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /opt/build.sh && bash /opt/build.sh && rm -rf /opt/build.sh && [ -f /docker-entrypoint.sh ] && chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
