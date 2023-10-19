# Shibboleth Single Sign-On (SSO) Set-Up

Setup may involve coordination between your institution's Identity and Access Management team and Dryad administrators depending if your Identity Provide (IdP) is releasing the proper attributes to the Dryad Service Provider (SP). 


Dryad requires that the following SAML attributes are released from your IdP:
- `eduPersonPrincipalName` (aka eppn)
- `mail` 

### Determine Proper Attribute Release
To determine if your IdP releases the correct attributes, run the following test:

https://datadryad.org/cgi-bin/PrintShibInfo.pl
 
Select your instition from the drop down list to be directed to your IdP.  Authenticate as you normally would.  Then you will be redirected back to the "Shibboleth Attribute Test - datadryad.org" page which outputs information received from your IdP. 

You will either see:

**Success!** -- indicates your IdP is indeed providing the attributes necessary to work with Dryad. In this case, copy and paste the information on that page and email it to: [dlowenberg@datadryad.org](mailto:dlowenber@datadryad.org)  with the subject line “IdP Success Message”. The team at California Digital Library supporting Dryad will then have the information it needs to add your IdP to the choices for federated partners. Once confirmed, you and your institution (and your users) are all set to login to Dryad using Shibboleth.  No other work is needed for login.

**Failure!** -- indicates your IdP is not yet releasing the necessary attributes to work properly with Dryad.  If this occurs, your IdP needs to be configured to release the proper attributes to the Dryad SP. 

Your Identity and Access Management team can use the following information to make the necessary changes:
- [Attribute Release Policies](https://github.com/CDL-Dryad/dryad-app/blob/main/documentation/membership/dyrad_attribute_release.xml)

Dryad Service Provider Metadata
- [Dryad stage/test service provider](https://mdq.incommon.org/entities/https%3A%2F%2Fdash-stg.cdlib.org%2Fshibboleth)
- [Dryad production service provider](https://mdq.incommon.org/entities/https%3A%2F%2Fdatadryad.org%2Fshibboleth)

Once configurations have occurred in both your IdP and on Dryad's SP, you can attempt the test again.

#### My instition is not included in the drop down list
This would indicate your institution is not a member of [InCommon](https://www.incommon.org/) or [eduGain](https://technical.edugain.org/metadata).  
Please have your Identity and Access Management team provide your Idp's metadata XML file.  (Please include Organization metadata in the file.)  You will also need to configure your IdP to release the above attributes (see [Attribute Release Policies](https://github.com/CDL-Dryad/dryad-app/blob/main/documentation/membership/dyrad_attribute_release.xml) above)

Once configurations have occurred in both your IdP and on Dryad's SP, you can attempt the test again.

### Additional resources

To look up community organizations for InCommon, check https://incommon.org/community-organizations/ as it may
be an additional resource beyond the shibinfo cgi above.

