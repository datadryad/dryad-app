# Installing Node/NPM on servers
Using React for file uploads requires Node and NPM to
be installed on the server for deployment with Capistrano. Capistrano now uses
Shakapacker (Ruby) which calls Webpack, which is a Javascript way to bundle
assets.

## Steps to manual install (solution for now)

1. Get Node and NPM.
```shell
cd ~/tmp
wget https://nodejs.org/dist/v14.16.1/node-v14.16.1-linux-x64.tar.xz
```
2. Extract Node.
```shell
mkdir ~/local
cd ~/local
tar -xf ~/tmp/node-v14.16.1-linux-x64.tar.xz
```
3. Symlink Node and NPM.
```shell
cd ~bin
ln -s ~/local/node-v14.16.1-linux-x64/bin/node node
ln -s ~/local/node-v14.16.1-linux-x64/bin/npm npm
```
4. Install Yarn, it will tell you where it installs and symlinks
```shell
npm install --global yarn
```
5. Symlink Yarn and yarnpkg.
```shell
cd ~/bin

ln -s ~/local/node-v14.16.1-linux-x64/bin/yarn yarn
ln -s ~/local/node-v14.16.1-linux-x64/bin/yarnpkg yarnpkg
```
6. Initialize the UI components
```shell
cd ~/dryad-app
yarn install
bin/webpack
```

## Upgrading Node

**Before performing an upgrade on production, test on other servers to ensure the new Node version is compatible!**

1. Install the version you desire
```
nvm install <version_number>
```
2. Ensure the version is used by the default account on the machine. Edit the `.bashrc` file, which has node configuration near the end
3. Restart Puma to connect it to the new Node version (on production machines, do this while the machine is out of the load balancer)
```
puma_restart.sh
```
