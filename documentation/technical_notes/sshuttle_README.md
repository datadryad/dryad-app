
Sshuttle is a method for connecting to firewalled servers, by proxying a
connection through a privileged server.

The `sshuttle.sh` script sets up the sshuttle service to intercept all requests
for Dryad's firewalled servers, and route them through `ftp.datadryad.org` as a
privileged machine. 

# How to set up sshuttle.sh script

## sshuttle.sh and SSH config

Proxy connections may be managed through an SSH config file (`.ssh/config`)
instead of through sshuttle. If you have changed your ssh config, and you run
into any difficulty with the instructions below, please start from a vanila copy
of the SSH config to be sure there aren't incompatible changes.

## Add environment variable for your FTP server connection info and test it manually

Add the following to a file such as .bash_profile so it loads into your environment
```bash
export DRYAD_FTP_CONNECT="bozotheclown@ftp.datadryad.org"
```
(Hint: change bozotheclown to your real username above)

Test that you can connect from your machine to the FTP server without a password prompt.

```bash
# change bozotheclown to your real username on the ftp server
ssh bozotheclown@ftp.datadryad.org
```

You should be able to connect automatically without a password from your machine and without additional prompts.
If not, add your public key to the authorized_keys for the account you are trying to connect to. Get
passwordless login working by ssh keys from your machine to the ftp server by ssh.

## Passwordless login for the individual Dryad servers

You do not need to add authorized keys to every Dryad server for your `username@ftp.datadryad.org`
account.

*However*, the way sshuttle works is that it will forward your local ssh public key (\<username\>@\<local_machine\>) to
to the Dryad servers. So you may need to go add the public key for your local machine account to
all Dryad server authorized key files for those you want to connect to.

If it doesn't forward your local public key then you'll need to add the key for `username@ftp.datadryad.org` to the servers instead.

## Install sshuttle on your machine

This will vary based on your OS type.  Use something like apt, yum or homebrew to install sshuttle.

## Run the sshuttle.sh script

Go into the location of your dryad-app directory and go to `dryad-app/config/script`

Example of starting the script from this directory:
```bash
$ ./sshuttle.sh start
Starting sshuttle and tunneling these IPs: 35.164.191.195 52.89.224.42 35.164.191.208 52.35.63.255 52.35.63.251 54.148.81.93 52.35.63.226 54.244.52.80 54.244.52.79 44.229.33.203 54.244.52.78
[local sudo] Password:
$
```

Example of connecting to an ssh server:
```bash
$ ssh uc3-dryaduix2-stg-2c.cdlib.org
Last login: Wed Mar 18 10:58:01 2020 from ec2-52-204-33-247.compute-1.amazonaws.com

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
No packages needed for security; 7 packages available
Run "sudo yum update" to apply all updates.
-bash-4.2$
```

Example of stopping sshuttle:
```bash
$ ./sshuttle.sh stop
$
```

Note: production servers will not work with this currently since IAS refused to allow access to
them through the `ftp.datadryad.org` server and only from other UC servers.  Those would require
double-tunneling (first to `ftp.datadryad.org` and then to some other server inside our IAS accounts).
