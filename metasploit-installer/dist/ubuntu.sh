#!/bin/bash

#
# rvmのインストールに必要なパッケージのインストール
# curlのインストール
#
sudo apt-get install -y curl
sudo apt-get install -y build-essential bison libc6-dev ncurses-dev
sudo apt-get install -y libffi-dev
sudo apt-get install -y openssl libssl-dev libyaml-dev
sudo apt-get install -y libreadline6 libreadline6-dev
sudo apt-get install -y automake autoconf pkg-config
sudo apt-get install -y git-core subversion
sudo apt-get install -y zlib1g zlib1g-dev
sudo apt-get install -y sqlite3 libsqlite3-dev libgdbm-dev
sudo apt-get install -y postgresql libpq-dev
sudo apt-get install -y libxml2-dev libxslt-dev
sudo apt-get install -y libpcap-dev

# rvmのインストール
if [ ! -e ~/.rvm ]; then
	curl -L https://get.rvm.io | bash
fi

# Activattion
source ~/.rvm/scripts/rvm

# rvmを最新バージョンへ更新
rvm get head
rvm reload

# ruby1.9.3のインストール
rvm install 1.9.3
rvm --default use 1.9.3

# ruby gemsの設定
rvm rubygems current


# Metasploitの取得
git clone https://github.com/rapid7/metasploit-framework
pushd metasploit-framework
	bundle install
popd

# vim: set nu ts=2 autoindent : #

