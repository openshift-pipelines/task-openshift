# This Docerfile is the environment where the test will be run in.
FROM registry.ci.openshift.org/openshift/release:golang-1.21

# Add kubernetes repository
ADD ci/kubernetes.repo /etc/yum.repos.d/

# Change baseurl for CentOS EOL workaround
# https://blog.centos.org/2023/04/end-dates-are-coming-for-centos-stream-8-and-centos-linux-7/ 
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum install -y kubectl httpd-tools jq make git which
RUN  rpm -Uvh https://github.com/tektoncd/cli/releases/download/v0.33.0/tektoncd-cli-0.33.0_Linux-64bit.rpm

# Serverless-Operator `make generated-files` needs helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN GOFLAGS='' go install github.com/mikefarah/yq/v3@latest

# go install creates $GOPATH/.cache with root permissions, we delete it here
# to avoid permission issues with the runtime users
RUN rm -rf $GOPATH/.cache

# Allow runtime users to add entries to /etc/passwd
RUN chmod g+rw /etc/passwd

ADD . .
