# Installing Node/NPM on servers
Since we're updating our servers to use React for file uploads it requires Node and NPM to be installed on the server
for deployment with Capistrano.  Capistrano now uses Webpacker (Ruby) which calls Webpack, which is a
Javascript way to bundle assets.

Right now we are using both Sprockets (asset pipeline) and Webpack.  As we move toward Rails 6, I
believe Webpacker is the default. Also, it appears that it's recommended to go through all Javascript
files to modernize them an make them more encapsulated rather than using Global scope for Javascript.
See for example https://rossta.net/blog/from-sprockets-to-webpack.html which walks through
decisions they made while upgrading.

It appears to me that we may run into significant challenges and may take significant time to
update our Javascript (especially with Rails Engines that we use of our own and possibly others
like Geoblacklight).

## Steps to manual install (solution for now)

1. Get Node and NPM.
```shell
cd ~/tmp
wget https://nodejs.org/dist/v14.16.1/node-v14.16.1-linux-x64.tar.xz
```
2. Extract Node.
```shell
cd ~/local
tar -xf ~/tmp/node-v14.16.1-linux-x64.tar.xz
```
3. Symlink Node and NPM.
```shell
cd bin
ln -s /apps/dryad/local/node-v14.16.1-linux-x64/bin/node node
ln -s /apps/dryad/local/node-v14.16.1-linux-x64/bin/npm npm
```
4. Install Yarn, it will tell you where it installs and symlinks
```shell
npm install --global yarn
```
5. Symlink Yarn and yarnpkg.
```shell
cd ~/local/bin

ln -s /apps/dryad/local/node-v14.16.1-linux-x64/bin/yarn yarn
ln -s /apps/dryad/local/node-v14.16.1-linux-x64/bin/yarnpkg yarnpkg
```
