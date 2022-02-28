data "aws_iam_policy_document" "lambda_invoke_assume" {
  statement {
    actions = [
      "sts:AssumeRole"]
    effect = "Allow"
    principals {
      identifiers = [
        "apigateway.amazonaws.com"]
      type = "Service"
    }
  }
}

// TODO - export role so this can be optionally added
//data "aws_iam_policy_document" "lambda_for_api-gw-lambda_invoke" {
//  statement {
//    actions = [
//      "lambda:InvokeFunction"]
//    effect = "Allow"
//    resources = [
//      module.custom_authoriser.function_arn]
//  }
//}