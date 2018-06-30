FROM ubuntu:16.04
MAINTAINER yamada28go

ENV DEBIAN_FRONTEND noninteractive

#set japanese mirror repository for apt
RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.iij.ad.jp/pub/linux/ubuntu/archive/%g" /etc/apt/sources.list

#install basic tools
RUN apt-get update && apt-get install -y \
	locales\
	tzdata\
	sudo\
	less

#Install and set SSH
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:hoge' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Upstart and DBus have issues inside docker. 
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# add user
RUN groupadd -g 1000 developer && \
    useradd -g developer -G sudo -m -s /bin/bash dev && \
    echo 'dev:dev' | chpasswd

# base
RUN apt-get install -y \
	ibus-mozc\
	dbus-x11\
	fonts-vlgothic\
	x11-apps\
	x11-xserver-utils

# Setup Japanese environment.
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && echo 'Asia/Tokyo' > /etc/timezone && date
RUN echo 'LC_ALL=ja_JP.UTF-8' > /etc/default/locale && echo 'LANG=ja_JP.UTF-8' >> /etc/default/locale &&  locale-gen ja_JP.UTF-8
ENV LC_CTYPE ja_JP.UTF-8

#-----
#VsCode Setup

RUN apt-get install -y \
	apt-transport-https \
	ca-certificates curl\
	gnupg\
	git\
	--no-install-recommends

# Add the vscode debian repo
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | apt-key add -
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list

RUN apt-get update && apt-get -y install \
	code \
	libasound2 \
	libatk1.0-0 \
	libcairo2 \
	libcups2 \
	libexpat1 \
	libfontconfig1 \
	libfreetype6 \
	libgtk2.0-0 \
	libpango-1.0-0 \
	libx11-xcb1 \
	libxcomposite1 \
	libxcursor1 \
	libxdamage1 \
	libxext6 \
	libxfixes3 \
	libxi6 \
	libxrandr2 \
	libxrender1 \
	libxss1 \
	libxtst6 \
	--no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get clean

#Copy user config files
COPY .bash_profile /home/dev/.bash_profile

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
