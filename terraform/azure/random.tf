resource "random_integer" "rnd_int" {
  min     = 1
  max     = 10000
}

resource "random_password" "mssql_admin" {
  for_each = toset(["mssql1", "mssql2", "mssql3", "mssql4", "mssql5", "mssql6", "mssql7"])

  length           = 32
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%*()-_=+[]{}<>:?"
}