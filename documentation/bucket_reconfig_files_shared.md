# Reconfiguring buckets for file sharing across organizations

The way to do this isn't straightforward, especially since we were lacking some pieces of
information about how CDL configured access for Merritt.  In the past, Merritt has been
using ACLs in our bucket but then those access control lists denied Dryad access to the
content.

Things to know

- Merritt access is controlled through an EC2 instance profile.
- ACL access mode cannot be disabled until you remove any foreign accounts first.
- Save canonical ID and you will be able to re-enable ACLs again later if other things break.
- A way to give Merritt access is by adding the CDL root account which delegates access to Merritt through CDL.

## Steps to allow both accounts to access without ACLs

1. Go to the bucket in the AWS console and click on the *Permissions* tab.
2. Click on *Edit* in the Access control list section.
3. Find the extra *Grantee* besides the default groups.  This is CDL's canonical ID.
   Make a copy of the ID if you want to re-enable ACLs later.
4. Click *Remove* on the CDL grantee and then *Save changes*.
5. Under the *Object Ownership* click *Edit*.
6. You can now choose *ACLs disabled* and then *Save changes*.  If you try this before
   removing the CDL grantee, you will get an error and it will not work and the error
   is not clear about what needs to happen.
7. Back in the bucket policy, edit the JSON to add a stanza like this, I'm omitting the cdl account id, but
   you can find it in the dev policy.  Also update the Resource for the correct bucket name.
```json
        {
            "Sid": "CDL Root",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<acct-id>:root"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::dryad-assetstore-merritt-dev",
                "arn:aws:s3:::dryad-assetstore-merritt-dev/*"
            ]
        }
```
8. This should enable CDL access without ACLs. You may need to talk with Martin if Merritt access doesn't work and
   he can check permissions and that the access is delegated to Merritt.

## To allow the the API user access from Dryad ui code

Add a stanza to the bucket allowing this user access:

```json
        {
            "Sid": "Stmt",
            "Effect": "Allow",
            "Principal": {
                "AWS": "<user-arn>"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::dryad-assetstore-merritt-dev",
                "arn:aws:s3:::dryad-assetstore-merritt-dev/*"
            ]
        }
```

If it's still not working, check policies on the user in IAM to see if there are other limits on the user access.