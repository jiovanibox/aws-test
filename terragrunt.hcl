remote_state {
  backend = "s3"
  config = {
    bucket                  = "${get_env("TF_ENV", "dev")}-backend-bucket-20240101test"
    key                     = "${get_env("TF_ENV", "dev")}/terraform.tfstate"
    region                  = "ap-northeast-1"
    encrypt                 = true
    dynamodb_table          = "kazue-ddb-table-not-created1111"
  }
}

