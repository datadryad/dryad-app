
Steps for setting up Dryad on a new EC2 machine with Amazon Linux
=================================================================

- Install an SSH key, so you can login to the machine directly
- git
```
sudo yum update
sudo yum install git
```
- emacs, ack
```
sudo yum install emacs-nox
mkdir emacs
curl "https://raw.githubusercontent.com/yoshiki/yaml-mode/master/yaml-mode.el" >emacs/yaml-mode.el
curl https://beyondgrep.com/ack-v3.7.0 > ~/bin/ack && chmod 0755 ~/bin/ack
```
- install mysql
```
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm #may need to hit enter twice
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y
sudo dnf install mysql-community-server -y
yum install mysql-devel
```
- check out the Dryad code
```
git clone https://github.com/CDL-Dryad/dryad-app.git
```
- copy in the deploy_dryad script
```
???TODO -- put script in repo and make the copy command
```
- install ruby
```
sudo yum install ruby
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison perl-core icu libicu-devel
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bash_profile
# restart the shell
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
git -C "$(rbenv root)"/plugins/ruby-build pull
cd dryad-app
rbenv install $(cat .ruby-version)
rbenv global $(cat .ruby-version)
sudo gem update --system --no-user-install
gem install libv8 -v '3.16.14.19' --
gem install therubyracer -v '0.12.3' --
gem install mysql2 -v '0.5.3' -- 
bundle install
- install node
```
sudo yum install nodejs
```
