#!/bin/bash

#
# rvmのインストールに必要なパッケージのインストール
# curlのインストール
#
sudo yum -y install curl

#
# 開発環境のインストール
#
sudo yum -y install git
sudo yum -y groupinstall "Development Tools"

#
# kernel-develのインストール
#
sudo yum -y install kernel-devel

#
# その他
#
yum -y install libpcap libpcap-devel

#
# PostgreSqlのインストール
#
sudo yum -y install postgresql postgresql-server postgresql-devel

#
# サービスの再起動
#
sudo service postgresql resatrt

#
# PostgreSQLの初期化
#
sudo su postgres -c 'initdb -D /var/lib/pgsql/data/'

# rvmのインストール
if [ ! -e ~/.rvm ]; then
	curl -L https://get.rvm.io | bash
fi

# pathの設定
if [ -e /usr/local/rvm ]; then
	# Activattion
	source /etc/bashrc
fi

# rvmを最新バージョンへ更新
rvm get head
rvm reload

# ruby1.9.3のインストール
rvm install 1.9.3
rvm use 1.9.3 --default

# ruby gemsの設定
rvm rubygems current

# Metasploitの取得
git clone https://github.com/rapid7/metasploit-framework
pushd metasploit-framework
	bundle install
popd

# vim: set nu ts=2 autoindent : #

