# VsCode　日本語環境設定済みベース
# 
# 以下サイトを参考とした
# 
# WSL(Ubuntu 18.04)上でVS Codeを動かす
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
# ローカル通信が前提となるためSSHの暗号形式を調整して、通信速度を最適化する。
# HW暗号化が使用できる場合、aes128-gcm@openssh.comのほうが早い可能性があるが、
# 対応していない環境まで考慮して使用しないものとする。
# 参考
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
#日本語環境セットアップに必要な基礎的な条件をセットアップするs
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

# VSCodeで必要なものをインストール
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

# VS Codeをインストール
# Ms公式でないと日本語入力が出来ないので注意が必要
RUN wget -O code.deb https://go.microsoft.com/fwlink/?LinkID=760868 &&\
    dpkg -i code.deb &&\
    rm code.deb

# APTコマンドをクリーンする
RUN rm -rf /var/lib/apt/lists/* &&\
    apt-get clean   

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
