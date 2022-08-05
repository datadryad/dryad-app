
Curator Virtual Environment
===================================

Rationale:
- Dryad curators need a standard baseline of computing capabilities to perform
  their jobs. This includes both hardware and software.
- Dryad curators are scattered geographically. It is impractical for each
  curator to receive a Dryad-issued computer and for Dryad to maintain that
  computer. It is much easier for us to provide a centralized platform that
  curators can use to supplement their personal computing equipment.
- Installing and managing a large variety of software can be a burden. It is
  better for this to be performed once on a central system than for each curator
  to manage this on their indiviual machines. 

Implementation:
- There is a machine in the Amazon AWS EC2 system that runs Windows.
- The machine is physically located in Ohio, which is relatively centered in the
  country. This minimizes lag as users work with the graphical environment.
- This machine allows users to login with a remote desktop.
- The machine is equipped with a large amount of storage space and a collection
  of software packages that are useful for curation.
- The directory `C:\DryadData` is accessible to all users. It is a place where
  curators can download data files and discus them with each other.
- `C:\DryadData\SoftwareShortcuts` contains links to the installed software packages.


Setup
=========

Initializing the machine
----------------------------

Normally, a machine should be initialized from an existing snapshot. In EC2,
select the snapshot and choose "create instance".

To properly configure a Windows Server
- Login with the password you obtain from EC2
  - Select the instance in EC2
  - Actions, Security, Get Windows Password.
- Reset the password for the Administrator, and save the new password
  - net user Administrator "new_password"


Creating users
---------------

- When creating a user DO NOT select "force password change on first login".
  This will prevent some users from connecting.
- DO select "password never expires". Otherwise, users will be locked out of
  their account when the password expires, and they won't be able to change it.
- In the same tool that you create the users, add them to the group
  "Remote Desktop Users"
- By default, only 2 simultaneous users are allowed. Dryad has installed "RDS
  User" Client Access Licenses (CALs) to allow more users.

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

Your account on the Curator Virtual Environment is all set.

If you are connecting from a PC, use the program "Remote Desktop Connection".
If you are connecting from a Mac, use the program "Microsoft Remote Desktop".

Machine name: 
Your username:
Temporary password:

When you login, you will receive a warning about security certificates. You can
ignore this warning. However, if you choose the option to "accept" the
certificate, you will not see the warning again.

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
- Some software is only available via the `Curator` account. The most notable
  software like this is Matlab.


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


Connecting from a Chromebook
============================

Chromebooks cannot use the Microsoft Remote Desktop protocol; they use the
Chrome Remote Desktop.

*Important note: the Chrome Remote Desktop can only be installed for one user at
 a time. It cannot be shared.*

First, set up the Remote Desktop on the Curator VE:
1. Log into the Curator VE in the target account, using Microsoft Remote Desktop.
2. Open chrome.
3. Open GMail, and ensure that you are using the same account that will be used on the chromebook
4. Go to https://remotedesktop.google.com
5. Choose "Access My Computer"
6. If asked, agree to install the Chrome Remote Desktop as an application.
7. Choose "Setup Remote Access"
8. Install everything and complete the setup

Then access the Remote Desktop on the Chromebook:
1. Login to the Chromebook using the same Google account as above.
2. Go to https://remotedesktop.google.com
3. Choose the machine from the list
4. When you first connect, you will see a screen that asks for
   "Ctrl+Alt+Delete". You cannot input this from the keyboard; you must use the
   pop-up window on the right side to send it.
5. When you get to the windows login screen, login with the windows account info


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


System Management
==================

What is taking up space on the machine?
- Run the app WinDirStat
- You can delete files directly from this app, so it's great for cleaning up junk

To reset the Administrator password if it is lost:
- Use the AWS Systems Manager
  - Don't try the convoluted setup documents, just use the "Quick Setup" from
    the main menus and select the machine you want.
- Once SSM has been initialized on the machine, you should be able to obtain
  console access using the EC2 "Connect" feature.
- When you are on the machine use "net user Administrator Password@123" to set
  the password

To get RDS licenses to work when something went wrong:
- see
  https://techgenix.com/remote-desktop-licensing-mode-is-not-configured-error/
- On a license server, install RDS licenses
- Configure the server to use the licenses
  - (running on a secondary server doesn't seem to work well)
Go to Run and type gpedit.msc to open the Group Policy Editor.
Navigate to Computer Configuration -> Administrative Templates -> Windows Components -> Remote Desktop Services -> Remote Desktop Session Host -> Licensing.
- Setup the machine people login to use the license server
- Ensure proper ports are open
- Must test to ensure its working in the RD Licensing Diagnoser
  - open Server Manager, and select Tools > Remote Desktop Services > RD Licensing Diagnoser.
- enable 
