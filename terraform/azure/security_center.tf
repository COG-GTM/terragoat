resource azurerm_security_center_subscription_pricing "pricing" {
  for_each = toset([
    "VirtualMachines",
    "SqlServers",
    "AppServices",
    "StorageAccounts",
    "KeyVaults",
    "ContainerRegistry",
    "KubernetesService",
  ])

  tier          = "Standard"
  resource_type = each.value
}

resource azurerm_security_center_contact "contact" {
  alert_notifications = true
  alerts_to_admins    = true
  email               = var.security_contact_email
}
