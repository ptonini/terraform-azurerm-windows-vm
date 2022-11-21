resource "random_password" "this" {
  length  = 16
  special = true
}

resource "azurerm_public_ip" "this" {
  count = var.public_access ? var.host_count : 0
  name = "${var.rg.name}-${var.name}${format("%04.0f", count.index + 1)}"
  resource_group_name = var.rg.name
  location = var.rg.location
  sku = "Standard"
  allocation_method = "Static"
  zones = [1, 2, 3]
}

resource "azurerm_network_interface" "this" {
  count = var.host_count
  name = "${var.rg.name}-${var.name}${format("%04.0f", count.index + 1)}"
  location = var.rg.location
  resource_group_name = var.rg.name
  ip_configuration {
    name = "internal"
    subnet_id = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = try(azurerm_public_ip.this[count.index].id, null)
  }
}

resource "azurerm_network_security_group" "this" {
  name = "${var.rg.name}-${var.name}"
  resource_group_name = var.rg.name
  location = var.rg.location
}

resource "azurerm_network_security_rule" "this" {
  for_each = var.ingress_rules
  name = "${var.rg.name}-${var.name}-${each.key}"
  resource_group_name = var.rg.name
  network_security_group_name = azurerm_network_security_group.this.name
  priority = 100 + index(keys(var.ingress_rules), each.key)
  direction = "Inbound"
  access = "Allow"
  protocol = each.value["protocol"]
  source_port_range = try(each.value["source_port_range"], "*")
  destination_port_range = try(each.value["destination_port_range"], "*")
  source_address_prefix = try(each.value["source_address_prefix"], "*")
  destination_address_prefix = try(each.value["destination_address_prefix"], "*")
}

resource "azurerm_network_interface_security_group_association" "this" {
  count = var.host_count
  network_interface_id = azurerm_network_interface.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this.id
}


# Virtual Machine

resource "azurerm_availability_set" "this" {
  count = var.high_availability ? 1 : 0
  name = "${var.rg.name}-${var.name}"
  resource_group_name = var.rg.name
  location = var.rg.location
  managed = true
}

resource "azurerm_windows_virtual_machine" "this" {
  count = var.host_count
  name = "${var.rg.name}-${var.name}${format("%04.0f", count.index + 1)}"
  computer_name = "${var.name}${format("%04.0f", count.index + 1)}"
  location = var.rg.location
  resource_group_name = var.rg.name
  size = var.size
  admin_username = coalesce(var.admin_username, "${var.name}-admin")
  admin_password = random_password.this.result
  availability_set_id = try(azurerm_availability_set.this.0.id, null)
  network_interface_ids = [
    azurerm_network_interface.this[count.index].id
  ]
  source_image_id = var.source_image_id
  os_disk {
    disk_size_gb = var.os_disk_size_gb
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account.primary_blob_endpoint
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference == null ? {} : {1 = var.source_image_reference}
    content {
      publisher = source_image_reference.value["publisher"]
      offer = source_image_reference.value["offer"]
      sku = source_image_reference.value["sku"]
      version = source_image_reference.value["version"]
    }
  }
  dynamic "plan" {
    for_each = var.plan == null ? {} : {1 = var.plan}
    content {
      name = plan.value["name"]
      product = plan.value["product"]
      publisher = plan.value["publisher"]
    }
  }
  identity {
    type = var.identity_type
    identity_ids = var.identity_ids
  }
  tags = var.tags
}

resource "azurerm_managed_disk" "this" {
  for_each = local.extra_disks
  name  = each.value["fullname"]
  location = var.rg.location
  resource_group_name = var.rg.name
  storage_account_type = each.value["storage_account_type"]
  create_option = "Empty"
  disk_size_gb = each.value["disk_size_gb"]

}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = local.extra_disks
  managed_disk_id = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.this[each.value["host_index"]].id
  lun = 10 + index(keys(var.extra_disks), each.value["basename"])
  caching = "ReadWrite"
}