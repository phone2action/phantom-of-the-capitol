#!/usr/bin/env bash

# stop setup script if any command fails
set -e

DEPENDENCIES="mysql-server curl imagemagick libmysql++-dev libpq-dev git"

random() {
    head -c $1 /dev/urandom | base64
}

mysql_root=$(random 20)
mysql_congress_forms=$(random 20)
sudo debconf-set-selections <<EOF
mysql-server-5.5 mysql-server/root_password password $mysql_root
mysql-server-5.5 mysql-server/root_password_again password $mysql_root
EOF

apt-get update
apt-get -y install $DEPENDENCIES

mysql -u root -p"$mysql_root" -e "create database if not exists congress_forms_development;  GRANT ALL PRIVILEGES ON congress_forms_development.* TO 'congress_forms'@'localhost' IDENTIFIED BY '$mysql_congress_forms';"

cd /vagrant

cp -a config/database-example.rb config/database.rb
cp -a config/congress-forms_config.rb.example config/congress-forms_config.rb

sed -i "s@^  :password.*@  :password => '$mysql_congress_forms',@" config/database.rb

HOME=/home/vagrant sudo -u vagrant /bin/bash <<EOF
curl -sSL https://get.rvm.io | bash -s stable
source /home/vagrant/.rvm/scripts/rvm
rvm install ruby-2.1.0

cd .
bundle install

bundle exec rake ar:create ar:schema:load
bundle exec rake congress-forms:clone_git

cd /home/vagrant
curl -Lo phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-i686.tar.bz2
tar -jxvf phantomjs.tar.bz2
EOF

ln -s /home/vagrant/phantomjs-1.9.7-linux-i686/bin/phantomjs /usr/bin/phantomjs