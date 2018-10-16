// This hooks into our identity provider
// Mash up of a variety of things:
// https://aws.amazon.com/code/integrate-shibboleth-with-aws-identity-and-access-management/
//
// https://aws.amazon.com/blogs/security/iam-policies-and-bucket-policies-and-acls-oh-my-controlling-access-to-s3-resources/
//

data "http" "shib_idp_metadata" {
  url = "https://shib-test.bu.edu/idp/shibboleth"
}


resource "aws_iam_saml_provider" "default" {
  name = "Shibboleth"
  saml_metadata_document = "${data.http.shib_idp_metadata.body}"
}

// sample IAM Role to be linked with the BU entitlement data - one can add someone by 
// doing the following on software39-ns:
//
// $ cd /local/CSO/data/special.requests
// $ ./entitlement-update.pl dsmk http://iam.bu.edu/spfilter-amazon-813161656966-website_blazars
// $ ./real-entitlement-update.pl dsmk http://iam.bu.edu/spfilter-amazon-813161656966-website_blazars
//
// This links dsmk with the IAM role  Shibboleth-website_blazars in the account 813161656966
//
// Once that is done people can log in by going to:
//
// https://shib-test.bu.edu/idp/profile/SAML2/Unsolicited/SSO?providerId=urn:amazon:webservices
//

// now lets create the IAM role

locals {
  aws_account_id = "813161656966"
}

// The following is a Terraform shorthand for the following json:
//
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Effect": "Allow",
//       "Action": [
//         "sts:AssumeRoleWithSAML",
//         "sts:AssumeRole"
//         ],
//       "Principal": { "Federated": "${aws_iam_saml_provider.default.arn}" }
//     }
//   ]
// }
// 
data "aws_iam_policy_document" "iam_for_saml_login" {
  statement {
    actions = [ "sts:AssumeRoleWithSAML", "sts:AssumeRole" ]
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = [ "${aws_iam_saml_provider.default.arn}" ]
    }
  }
}

// first we need a power-user role
//
resource "aws_iam_role" "poweruser" {
  name = "Shibboleth-poweruser"

  assume_role_policy = "${data.aws_iam_policy_document.iam_for_saml_login.json}"
}

resource "aws_iam_role_policy_attachment" "poweruser-access-policy" {
    role = "${aws_iam_role.poweruser.name}"
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

// now an S3 access role
//
data "aws_iam_policy_document" "blazars_access" {
  // this is necessary for the web console access (unless we want to have them do the Shibboleth login 
  // followed by a specific URL to the bucket such as:
  //
  // https://s3.console.aws.amazon.com/s3/buckets/rexden-public-bucket
  //
  statement {
    actions = [ "s3:GetBucketLocation", "s3:ListAllMyBuckets" ]
    effect = "Allow"

    resources = [ "*" ]
  }

  // now grant access to a specific path on a specific bucket
  statement {
    actions = [ "s3:*" ]
    effect = "Allow"

    resources = [ 
      "${aws_s3_bucket.public.arn}/blazars",
      "${aws_s3_bucket.public.arn}/blazars/*"
    ]
  }
}

resource "aws_iam_role" "blazars_role" {
  name = "Shibboleth-website_blazars"

  assume_role_policy = "${data.aws_iam_policy_document.iam_for_saml_login.json}"

  // increase the max session duration from 1hr to 8hr (so a working day?)
  max_session_duration = 28800
}

resource "aws_iam_policy" "blazars" {
  name = "blazars-policy"
  policy = "${data.aws_iam_policy_document.blazars_access.json}"
}

resource "aws_iam_role_policy_attachment" "blazars-access-policy" {
  role = "${aws_iam_role.blazars_role.name}"
  policy_arn = "${aws_iam_policy.blazars.arn}"
}


// the below is from when we were trying Cognito pools - we should ignore this for now
/*
resource "aws_cognito_identity_pool" "shib" {
  identity_pool_name = "BU IdP"
  allow_unauthenticated_identities = false

  // cognito_identity_providers {
  //} 

  saml_provider_arns = [ "${aws_iam_saml_provider.default.arn}" ]
}
*/
