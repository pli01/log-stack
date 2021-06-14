FROM fluent/fluentd:v1.1.3-debian
ARG RUBY_URL
ARG MIRROR_DEBIAN
COPY Gemfile Gemfile.lock /
COPY build.sh /opt/build.sh
RUN ( set -ex ; chmod +x /opt/build.sh && bash /opt/build.sh )
