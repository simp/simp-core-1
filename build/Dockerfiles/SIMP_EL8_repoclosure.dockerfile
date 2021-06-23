# To build using docker, run:
#
# ```sh
# docker build \
#   --tag "simp-core-repoclosure:el8.$(git rev-parse --short HEAD)" \
#   --file build/Dockerfiles/SIMP_EL8_repoclosure.dockerfile build/Dockerfiles/repoclosure
# ```
#
# To build using podman, run:
# ```sh
# podman build \
#   --tag "simp-core-repoclosure:el8.$(git rev-parse --short HEAD)" \
#   --file build/Dockerfiles/SIMP_EL8_repoclosure.dockerfile
# ```
#
# After building, you will probably want to mount your ISO directory using
# something like the following:
#
# If you want to save your container for future use, you use use the `docker
# commit` command
#   * docker commit <running container ID> el8_repoclosure
#   * docker run -it el8_repoclosure
FROM centos:8
ENV REPOCLOSURE_INSTALLROOT=/opt/dnf_repoclosure_test

RUN mkdir -p "$REPOCLOSURE_INSTALLROOT"
RUN dnf install -y epel-release
RUN dnf install -y epel-release vim-enhanced jq tree # upgrade epel-release
RUN dnf module enable -y ruby:2.7 && dnf install -y ruby rubygem-{json,bundler}

CMD /bin/bash
#ENTRYPOINT ['

