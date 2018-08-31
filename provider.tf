provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/home/dsmk/.aws/credentials"
  // this is our sandbox account
  //profile                 = "w2c-nonprod"
  //profile                 = "default"
  profile                 = "rexden"
}
