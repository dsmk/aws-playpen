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

resource "aws_iam_role" "blazars_role" {
  name = "Shibboleth-website_blazars"

  assume_role_policy = "${data.aws_iam_policy_document.iam_for_saml_login.json}"
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
