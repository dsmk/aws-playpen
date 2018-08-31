// This hooks into our identity provider

data "http" "shib_idp_metadata" {
  url = "https://shib.bu.edu/idp/shibboleth"
}


resource "aws_iam_saml_provider" "default" {
  name = "shib.bu.edu"
  saml_metadata_document = "${data.http.shib_idp_metadata.body}"
}

resource "aws_cognito_identity_pool" "shib" {
  identity_pool_name = "BU IdP"
  allow_unauthenticated_identities = false

  /* cognito_identity_providers {
  } */

  saml_provider_arns = [ "${aws_iam_saml_provider.default.arn}" ]
}

