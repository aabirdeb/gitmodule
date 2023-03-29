#Resource group
module "resource_group" {
  source      = "/home/bapi/Desktop/applo/modules/resource_group"
  environment = "infra-test"
  location    = "centralus"
  role        = "unit-test-storageacount"
  client_name = "voyager"
  owner       = "systemsengineering@vca.com"
  creator     = "systemsengineering@vca.com"
  tags = {
    role = "unit-test"
  }
}

##network vnet##
module "network" {
  source              = "/home/bapi/Desktop/applo/modules/vnet"
  role                = "test"
  resource_group_name = module.resource_group.resource_group_name
  location            = "centralus"
  environment         = "infra-test"
  client_name         = "voyager"
  cidr_range          = "30.0.0.0/21"
  tags = {
    role = "unit-test"
  }

  subnets = {
    data-storage = {
      cidr                                           = "30.0.0.0/23",
      nsg-association                                = ""
      route-table                                    = ""
      enforce_private_link_endpoint_network_policies = true
    },
    test-subnet = {
      cidr                                           = "30.0.2.0/24",
      nsg-association                                = ""
      route-table                                    = ""
      service-endpoint                               = true
    },
  }
  serviceendpoint = ["Microsoft.Storage"]
}



module "actiongroup" {
  source              = "/home/bapi/Desktop/applo/modules/azure_actiongroup"
  resource_group_name = module.resource_group.resource_group_name
  environment         = "infra-test-action"
  client_name         = "voyager"
  role                = "unit-test"

  actiongroup = [
    {
      name                      = "STG Sev 1 Notifcation Group"
      shortname                 = "Sev1"
      armrolereceiver           = []
      automationrunbookreceiver = []
      azureapppushreceiver      = []
      emailreceiver = [
        {
          name                    = "Sev1Email"
          email_address           = "asd@asd.com"
          use_common_alert_schema = true
        },
        {
          name                    = "Sev2Email"
          email_address           = "asd2@asd.com"
          use_common_alert_schema = true
        }
      ]
      smsreceiver     = []
      webhookreceiver = []
    }
  ]

  tags = {
    role = "unit-test"
  }

}
module "logic_app" {
  source              = "/home/bapi/Desktop/applo/modules/logic_app"
  role                = "test"
  client_name         = "voyager"
  resource_group_name = module.resource_group.resource_group_name
  location            = "centralus"
  owner               = "systemsengineering@vca.com"
  creator             = "systemsengineering@vca.com"
  environment         = "infra-test"
  tags = {
    role = "unit-test"
  }

}

module "storage" {
  source                   = "/home/bapi/Desktop/applo/modules/storage_account"
  role                     = "test1"
  resource_group_name      = module.resource_group.resource_group_name
  location                 = "centralus"
  environment              = "testinfra"
  client_name              = "vca"
  owner                    = "systemsengineering@vca.com"
  creator                  = "systemsengineering@vca.com"
  subnet_id                = module.network.vnet_subnets["data-storage"].id
  account_replication_type = "LRS"
  account_kind             = "Storage"
  allowsubnet_id           = module.network.vnet_subnets["test-subnet"].id

  storagealert = [
    {
      name        = "Account-Availability"
      description = "Action will be triggered Whenever the average availability is less than threshold",
      metric_name = "Availability"
      severity    = 3
      enabled     = false
      aggregation = "Average"
      operator    = "LessThan"
      threshold   = 100
      actiongroup = module.actiongroup.actiongroup_id["STG Sev 1 Notifcation Group"].id
      dimensions  = []

    },
    {
      name        = "Account-SuccessE2ELatency"
      description = "Action will be triggered Whenever the average success e2e latency is greater than threshold",
      metric_name = "SuccessE2ELatency"
      severity    = 3
      enabled     = false
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 100
      actiongroup = module.actiongroup.actiongroup_id["STG Sev 1 Notifcation Group"].id
      dimensions  = []

    },
    {
      name        = "Account-Transactions"
      description = "Action will be triggeredthe total transactions is greater or less than dynamic thresholds",
      metric_name = "Transactions"
      severity    = 3
      enabled     = false
      aggregation = "Total"
      operator    = "GreaterThan"
      threshold   = 100000
      actiongroup = module.actiongroup.actiongroup_id["STG Sev 1 Notifcation Group"].id
      dimensions  = []

    },
  ]
  storageactivityalert = [
    {
      name           = "Account-Delete"
      description    = "Action will be triggeredthe total transactions is greater or less than dynamic thresholds",
      operation_name = "Microsoft.Storage/storageAccounts/delete"
      category       = "Recommendation"
      actiongroup    = module.actiongroup.actiongroup_id["STG Sev 1 Notifcation Group"].id
    },
    {
      name           = "Account-CreateorUpdate"
      description    = "Action will be triggeredthe total transactions is greater or less than dynamic thresholds",
      operation_name = "Microsoft.Storage/storageAccounts/write"
      category       = "Recommendation"
      actiongroup    = module.actiongroup.actiongroup_id["STG Sev 1 Notifcation Group"].id
    }
  ]

  tags = {
    role = "unit-test"
  }

}


