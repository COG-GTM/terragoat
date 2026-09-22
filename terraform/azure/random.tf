resource "random_integer" "rnd_int" {
  min     = 1
  max     = 10000
}

resource "random_password" "sql_server_admin" {
  length           = 24
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "postgresql_admin" {
  length           = 24
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
