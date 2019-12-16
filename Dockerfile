# VsCode�@���{����ݒ�ς݃x�[�X
# 
# �ȉ��T�C�g���Q�l�Ƃ���
# 
# WSL(Ubuntu 18.04)���VS Code�𓮂���
# https://qiita.com/Daisuke-Otaka/items/8f031f5110008233b7f9


FROM ubuntu:18.04
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
RUN apt-get update && apt-get install -y openssh-server && \
    mkdir /var/run/sshd &&\
    echo 'root:hoge' | chpasswd &&\
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&\
    echo "X11UseLocalhost no" >> /etc/ssh/sshd_config &&\
    /usr/bin/ssh-keygen -A &&\
# ���[�J���ʐM���O��ƂȂ邽��SSH�̈Í��`���𒲐����āA�ʐM���x���œK������B
# HW�Í������g�p�ł���ꍇ�Aaes128-gcm@openssh.com�̂ق��������\�������邪�A
# �Ή����Ă��Ȃ����܂ōl�����Ďg�p���Ȃ����̂Ƃ���B
# �Q�l
# https://possiblelossofprecision.net/?p=2255
 echo "Ciphers  aes128-ctr,aes128-gcm@openssh.com" >> /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Upstart and DBus have issues inside docker. 
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# add user
RUN groupadd -g 1000 developer && \
    useradd -g developer -G sudo -m -s /bin/bash dev && \
    echo 'dev:dev' | chpasswd

# base
RUN apt-get update &&  apt-get install -y \
    dbus-x11\
    fonts-vlgothic\
    x11-apps\
    x11-xserver-utils

# Setup Japanese environment.
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && echo 'Asia/Tokyo' > /etc/timezone && date &&\
    echo 'LC_ALL=ja_JP.UTF-8' > /etc/default/locale && echo 'LANG=ja_JP.UTF-8' >> /etc/default/locale &&  locale-gen ja_JP.UTF-8
ENV LC_CTYPE ja_JP.UTF-8

#-----
#���{����Z�b�g�A�b�v�ɕK�v�Ȋ�b�I�ȏ������Z�b�g�A�b�v����s
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates curl\
    gnupg\
    git\
    --no-install-recommends

RUN apt-get update && apt-get install -y \
    language-pack-ja \
    dbus-x11\
    fcitx-mozc\
    fonts-noto-cjk\
    fonts-noto-hinted   

RUN update-locale LANG=ja_JP.UTF-8
RUN sudo sh -c "dbus-uuidgen > /var/lib/dbus/machine-id"

# VSCode�ŕK�v�Ȃ��̂��C���X�g�[��
RUN apt-get update && apt-get -y install \
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
    libnotify4\
    libnss3\
    --no-install-recommends

#Copy user config files
COPY .bash_profile /home/dev/.bash_profile
RUN chown dev:developer /home/dev/.bash_profile &&\
    chmod -x /home/dev/.bash_profile

# VS Code���C���X�g�[��
# Ms�����łȂ��Ɠ��{����͂��o���Ȃ��̂Œ��ӂ��K�v
RUN wget -O code.deb https://go.microsoft.com/fwlink/?LinkID=760868 &&\
    dpkg -i code.deb &&\
    rm code.deb

# APT�R�}���h���N���[������
RUN rm -rf /var/lib/apt/lists/* &&\
    apt-get clean   

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
