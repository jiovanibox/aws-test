include {
  path = find_in_parent_folders()
}

terraform {
  source = "./"
}

inputs = {
  name    = "pj-1"
}
