// Lambda@Edge definitions
//
// https://gist.github.com/smithclay/e026b10980214cbe95600b82f67b4958
//

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "index.js"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename = "lambda_function.zip"
  function_name = "test_lambda"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime = "nodejs6.10"
}

data "aws_iam_policy_document" "iam_for_lambda_assume" {
  statement {
    actions = [ "sts:AssumeRole" ]
    effect = "Allow"
    sid = ""

    principals {
      type = "AWS"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    { 
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [ "lambda.amazonaws.com", "edgelambda.amazonaws.com" ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

