resource "azurerm_role_definition" "example" {
  name        = "my-custom-role"
  scope       = azurerm_resource_group.example.id
  description = "This is a custom role created via Terraform"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/deployments/read",
      "Microsoft.Resources/deployments/operations/read",
    ]
    not_actions = [
      "Microsoft.Authorization/*/Delete",
      "Microsoft.Authorization/*/Write",
      "Microsoft.Authorization/elevateAccess/Action",
    ]
  }

  assignable_scopes = [
    azurerm_resource_group.example.id
  ]
}
