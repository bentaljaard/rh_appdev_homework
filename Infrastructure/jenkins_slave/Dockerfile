FROM docker.io/openshift/jenkins-slave-maven-centos7:latest
USER root
RUN yum -y install skopeo apb && \
    yum clean all
USER 1001
