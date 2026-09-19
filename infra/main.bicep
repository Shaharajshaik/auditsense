@description('The Azure region for all resources.')
param location string = resourceGroup().location

@description('Resource ID of an existing user-assigned managed identity to attach to the app. Leave empty to use a system-assigned identity.')
param existingManagedIdentityResourceId string = ''

@description('The base name for resources. Must be globally unique for Storage and App Service host names.')
param baseName string = 'auditsense${uniqueString(resourceGroup().id)}'

@description('The Python runtime stack for the App Service.')
param appServiceRuntime string = 'PYTHON|3.12'

@description('The SKU for the App Service plan.')
param appServicePlanSku object = {
  name: 'B1'
  tier: 'Basic'
}

@description('The name of the Azure OpenAI resource.')
param openAiName string = '${baseName}-openai'

@description('The Azure OpenAI model deployment name.')
param openAiModelName string = 'gpt-4o-mini'

@description('The Azure OpenAI model version.')
param openAiModelVersion string = '2024-07-18'

@description('The Azure OpenAI deployment capacity.')
param openAiCapacity int = 1

@description('The name of the Azure Storage account used for uploads.')
param storageAccountName string = toLower(replace('${baseName}storage', '-', ''))

@description('The name of the Azure SQL server.')
param sqlServerName string = '${baseName}-sql'

@description('The SQL administrator login name.')
param sqlAdminLogin string = 'sqladminuser'

@description('The SQL administrator password.')
@secure()
param sqlAdminPassword string

@description('The Azure SQL database name.')
param sqlDatabaseName string = 'auditsense-db'

@description('The App Service plan name.')
param appServicePlanName string = '${baseName}-plan'

@description('The web app name.')
param webAppName string = '${baseName}-app'

@description('The Document Intelligence resource name.')
param documentIntelligenceName string = '${baseName}-docintel'

@description('The Application Insights name.')
param applicationInsightsName string = '${baseName}-appi'

@description('The Log Analytics workspace name.')
param logAnalyticsWorkspaceName string = '${baseName}-logs'

@description('The environment tag for the deployed resources.')
param environment string = 'dev'

var appServicePlanKind = 'linux'
var appServiceSkuName = appServicePlanSku.name
var appServiceSkuTier = appServicePlanSku.tier
var openAiKind = 'OpenAI'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
  tags: {
    environment: environment
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
  tags: {
    environment: environment
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: environment
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
  }
}

resource uploadContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: 'uploads'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
  tags: {
    environment: environment
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: sqlDatabaseName
  parent: sqlServer
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
  }
  tags: {
    environment: environment
  }
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  kind: openAiKind
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
  tags: {
    environment: environment
  }
}

resource openAiModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: openAiModelName
  parent: openAi
  sku: {
    name: 'Standard'
    capacity: openAiCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: openAiModelName
      version: openAiModelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
}

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: documentIntelligenceName
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: documentIntelligenceName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
  tags: {
    environment: environment
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  kind: appServicePlanKind
  sku: {
    name: appServiceSkuName
    tier: appServiceSkuTier
  }
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
  }
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: empty(existingManagedIdentityResourceId) ? {
    type: 'SystemAssigned'
  } : {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${existingManagedIdentityResourceId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: appServiceRuntime
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccount.name
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_KEY'
          value: storageAccount.listKeys().keys[0].value
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAi.properties.endpoint
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: openAi.listKeys().key1
        }
        {
          name: 'AZURE_OPENAI_MODEL_NAME'
          value: openAiModelName
        }
        {
          name: 'AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT'
          value: documentIntelligence.properties.endpoint
        }
        {
          name: 'AZURE_DOCUMENT_INTELLIGENCE_KEY'
          value: documentIntelligence.listKeys().key1
        }
        {
          name: 'AZURE_SQL_SERVER'
          value: sqlServer.properties.fullyQualifiedDomainName
        }
        {
          name: 'AZURE_SQL_DATABASE'
          value: sqlDatabase.name
        }
        {
          name: 'AZURE_SQL_ADMIN_LOGIN'
          value: sqlAdminLogin
        }
        {
          name: 'AZURE_SQL_ADMIN_PASSWORD'
          value: sqlAdminPassword
        }
      ]
    }
  }
  tags: {
    environment: environment
  }
}

output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output storageAccountName string = storageAccount.name
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output openAiEndpoint string = openAi.properties.endpoint
output documentIntelligenceEndpoint string = documentIntelligence.properties.endpoint
