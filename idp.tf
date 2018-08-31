// This hooks into our identity provider

resource "aws_cognito_user_pool" "example" {
  name = "example-pool"
  auto_verified_attributes = [ "email" ]
}

resource "aws_cognito_identity_provider" "example_provider" {
  user_pool_id = "${aws_cognito_user_pool.example.id}"
  provider_name = "shib.bu.edu"
  provider_type = "SAML"

  provider_details {
    MetadataURL = "https://shib.bu.edu/idp/shibboleth"
  }

}

