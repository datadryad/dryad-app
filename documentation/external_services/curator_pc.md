
Curator PC
==============

AWS allows running servers that you can connect with a virtual desktop. We are
using this feature for the curator PC.

How the machine runs:
- We use EC2. There is also an option via Lightsail, but the Lightsail servers
  are far less configurable, and server specs cannot be changed without
  completely rebuilding the server.
- To minimize lag, we run on Amazon's datacenter in Ohio.
  

To properly configure a Windows Server
- Login with the password you obtain from EC2
  - Select the instance in EC2
  - Actions, Security, Get Windows Password.
- Reset the password for the Administrator, and save the new password
  - net user Administrator "new_password"
- Older versions of Windows Server (pre-2022) default to having
  only IE installed. IE is not compatible with modern websites, and should be
  removed
  
Creating users
---------------

- When creating a user DO NOT select "force password change on first login".
  This will prevent some users from connecting.
- DO select "password never expires". Otherwise, users will be locked out of
  their account when the password expires, and they won't be able to change it.
- In the same tool that you create the users, add them to the group
  "Remote Desktop Users"
- By default, only 2 simultaneous users are allowed. If you want more
  - Install Remote Desktop Services
    - Install via Windows Admin Center; the Server Manager does not work correctly
  - Purchase “RDS User” Client Access Licenses (CALs)
  - Install them through the Remote Desktop Licensing Manager

To connect to Windows Server
- PC users connect with Remote Desktop Connection
- Mac users download the app Microsoft Remote Desktop
- Connect using the IP and the assigned user/passwoord
- A user account may only be logged in from one place at a time
- The first time you connect, you will see an error about a Security
  Certificate. Choose to View the certificate and Accept it, then you will no
  longer receive the message.

Downloads
- File downloads will continue while your local machine sleeps
- Users must update their browser settings so files download into the Data drive

Accounts
--------------------

Special accounts:
- Administrator -- The primary superuser. This account cannot be renamed or removed.
- Curator -- A shared account that curators may use to access software that can
  only run from a single account.
- CuratorAdmin -- An administrative account that cannot login (it's not part of the group Remote
  Desktop Users). It is intended for curators to authorize occasional
  administrative activities, such as installing temporary software.
 - Testy -- A "normal" user account that is sometimes used for testing new features.


Instructions for new users
===========================

Your account on the curator PC is all set.

If you are connecting from a PC, use Remote Desktop Connection.
If you are connecting from a Mac, use Microsoft Remote Desktop.

Machine name: 
Your username:
Temporary password:

You will receive a warning about security certificates, which you can ignore.

Once you have logged in, please change your password using this process:
1. In the PC, open Settings
2. Search for ‘password’
3. Select ‘Change Your Password’
4. Choose ‘Password’ and press the ‘Change’ button
5. Complete the change process
6. The next time you connect with the Remote Desktop, you will need to update
   the password that it uses to connect.

General usage tips:
- Store all files that you are curating in `C:\DryadData\<your_account_name>` --
  this will allow other curators to view the files if needed.
- You may store personal files in your account, but this should rarely be
  needed.
- Shortcuts to run useful software are in `C:\DryadData\SoftwareShortcuts`
- Some software is only available to the `Curator` account.


Installing other software
--------------------------

If you encounter a need for software that is not installed, file a development
ticket to have it added.

If you need a "nonstandard" piece of software that you expect will
not be used ever again, you can install it yourself.
1. When you start the install, the PC will ask you for an admin account.
2. Choose “More Choices”
3. Select the account CuratorAdmin
   - This account has the same password as the Curator account, but it’s only
     for installing software (you can’t use it to login).


Dryad and Linux
=================

Using Ubuntu Linux on Windows
-----------------------------

To setup Ubuntu in your account, use the Windows Subsystem for Linux. Open the
Command Prompt (or Windows Power Shell) and run:
`wsl --install -d Ubuntu`

The first time, it will take a while to set up, and finish by asking you to
create a user account. The Ubuntu account only exists *within* your Windows account,
so it does not need to be secure. It can simply be `dryad` with password `dryad`.

After the initial setup, to access Ubuntu, you can simply type `wsl`.

To access files in/out of the Ubuntu drive:
- From Windows Command Prompt or File Explorer, the Ubuntu files have a path like:
  `\\wsl$\Ubuntu-20.04\home\dryad\*`
- From Ubuntu, the Windows files have a path like
  `/mnt/c/DryadData`

Python is available in Ubuntu as `python3`.


Using the Dryad code on Windows within Ubuntu
---------------------------------------------

Once ubuntu is set up:
```
sudo apt update
sudo apt-get install mysql-server mysql-client libmysqlclient-dev
sudo apt-get install libxml2 libxml2-dev patch curl build-essential libreadline-dev
sudo apt-get install ruby-dev
sudo apt install rbenv
rbenv init
(add the init command to .bashrc)
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install 2.6.6
git clone https://github.com/CDL-Dryad/dryad-app.git
cd dryad-app
sudo gem install bundler:2.2.27
cd script/file-download
bundle install
(put server and API credentials into download.rb)
./download.rb <URL to dataset>
```

Using the Dryad code on Windows (natively)
------------------------------------------

Windows has difficulty cloning the Dryad code due to a filename with crazy
characters, which we intentionally created to test filenames.

The code should be able to be cloned with:
`git clone -c core.protectNTFS=false -n https://github.com/CDL-Dryad/dryad-app.git`

Download the [Ruby+Devkit 2.6.8-1](https://rubyinstaller.org/downloads/)
(x64) and install it as administrator. Install the option "with MinGW", since
it's needed for compiling some ruby gems that might have native-ish code.

The "bundle install" command works from the script\file-download subdirectory.
