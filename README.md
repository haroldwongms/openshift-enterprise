# OpenShift Enterprise with Username / Password authentication for OpenShift

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fharoldwongms%2Fopenshift-enterprise%2Fmaster%2Fazuredeploy.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fharoldwongms%2Fopenshift-enterprise%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template deploys OpenShift Enterprise with basic username / password for authentication to OpenShift. It includes the following resources:

|Resource           |Properties                                                                                                                          |
|-------------------|------------------------------------------------------------------------------------------------------------------------------------|
|Virtual Network    |**Address prefix:** 10.0.0.0/16<br />**Master subnet:** 10.0.0.0/24<br />**Node subnet:** 10.0.1.0/24                               |
|Load Balancer      |2 probes and two rules for TCP 80 and TCP 443 <br/> NAT rules for SSH on Ports 2200-220X                                                                                  |
|Public IP Addresses|OpenShift Master public IP<br />OpenShift Router public IP attached to Load Balancer                                                |
|Storage Accounts   |2 Storage Accounts                                                                                                                  |
|Virtual Machines   |Single master<br />User-defined number of nodes<br />All VMs include a single attached data disk for Docker thin pool logical volume|

## Prerequisites

### Generate SSH Keys

You'll need to generate a pair of SSH keys in order to provision this template. Ensure that you do not include a passcode with the private key. <br/>
If you are using a Windows computer, you can download puttygen.exe.  You will need to export to OpenSSH (from Conversions menu) to get a valid Private Key for use in the Template.<br/>
From a Linux or Mac, you can just use the ssh-keygen command.

### Create Key Vault to store SSH Private Key

You will need to create a Key Vault to store your SSH Private Key that will then be used as part of the deployment.

1. Create KeyVault using Powershell <br/>
  a.  Create new resource group: New-AzureRMResourceGroup -Name 'ResourceGroupName' -Location 'West US'<br/>
  b.  Create key vault: New-AzureRmKeyVault -VaultName 'KeyVaultName' -ResourceGroup 'ResourceGroupName' -Location 'West US'<br/>
  c.  Create variable with sshPrivateKey: $securesecret = ConvertTo-SecureString -String '[copy ssh Private Key here - including line feeds]' -AsPlainText -Force<br/>
  d.  Create Secret: Set-AzureKeyVaultSecret -Name 'SecretName' -SecretValue $securesecret -VaultName 'KeyVaultName'<br/>

2. Create Key Vault using Azure CLI - must be run from a Linux machine (can use Azure CLI container from Docker for Windows) or Mac<br/>
  a.  Create new Resource Group: azure group create \<name\> \<location\> <br/>
         Ex: [azure group create ResourceGroupName 'East US'] <br/>
  b.  Create Key Vault: azure keyvault create -u \<vault-name\> -g \<resource-group\> -l \<location\><br/>
         Ex: [azure keyvault create -u KeyVaultName -g ResourceGroupName -l 'East US'] <br/>
  c.  Create Secret: azure keyvault secret set -u \<vault-name\> -s \<secret-name\> -w \<secret-value\><br/>
         Ex: [azure keyvault secret set -u KeyVaultName -s SecretName -w <Paste private key here>] <br/>
     1. Do not include the first line "-----BEGIN RSA PRIVATE KEY-----" and the last line "-----END RSA PRIVATE KEY-----" <br/>
  d.  Enable the Keyvvault for Template Deployment: azure keyvault set-policy -u \<vault-name\> --enabled-for-deployment true <br/>
         Ex: [azure keyvault set-policy -u KeyVaultName --enabled-for-deployment true] <br/>

### azuredeploy.Parameters.json File Explained

1.  masterVmSize: Select from one of the allowed VM sizes listed in the azuredeploy.json file
2.  nodeVmSize: Select from one of the allowed VM sizes listed in the azuredeploy.json file
3.  openshiftMasterHostName: Host name for the Master Node
4.  openshiftMasterPublicIpDnsLabelPrefix: A unique Public DNS name to reference the Master Node by
5.  nodeLbPublicIpDnsLabelPrefix: A unique Public DNS name to reference the Node Load Balancer by.  Used to access deployed applications
6.  nodePrefix: prefix to be prepended to create host names for the Nodes
7.  nodeInstanceCount: Number of Nodes to deploy
8.  adminUsername: Admin username for both OS login and OpenShift login
9.  adminPassword: Admin password for both OS login and OpenShift login
10. cloudAccessUsername: Your Cloud Access subscription user name
11. cloudAccessPassword: The password for your Cloud Access subscription
12. cloudAccessPoolId: The Pool ID that contains your RHEL and OpenShift subscriptions
13. sshPublicKey: Copy your SSH Public Key here
14. subscriptionId: Your Subscription ID<br/>
    a. PowerShell: get-AzureAccount
	b. Azure CLI: azure account show  - Field is ID
15. keyVaultResourceGroup: The name of the Resource Group that contains the Key Vault
16. keyVaultName: The name of the Key Vault you created
17. keyVaultSecret: The Secret Name you used when creating the Secret
18. defaultSubDomain: The default subdomain to be used for routing to applications (e.g. apps.mydomain.com)

## Deploy Template

Once you have collected all of the prerequisites for the template, you can deploy the template by clicking Deploy to Azure or populating the *azuredeploy.parameters.json* file and executing Resource Manager deployment commands with PowerShell or the xplat CLI.

### NOTE

The OpenShift Ansible playbook does take a while to run when using VMs backed by Standard Storage. VMs backed by Premium Storage are faster. If you want Premimum Storage, select a DS or GS series VM.
<hr />
Be sure to follow the OpenShift instructions to create the ncessary DNS entry for the OpenShift Router for access to applications.

### Additional OpenShift Configuration Options
 
You can configure additional settings per the official [OpenShift Enterprise Documentation](https://docs.openshift.com/enterprise/3.2/welcome/index.html).
