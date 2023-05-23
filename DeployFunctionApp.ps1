
#https://github.com/kubasiak/Azure-Cognitive-Search-Azure-OpenAI-Accelerator/blob/main/01-Load-Data-ACogSearch.ipynb

param($subscription, $tenantid )

$Script:args=""
write-host "Num Args: " $PSBoundParameters.Keys.Count
foreach ($key in $PSBoundParameters.keys) {
    $Script:args+= "`$$key=" + $PSBoundParameters["$key"] + "  "
}
write-host $Script:args


write-host $PSBoundParameters["$subscription"]

az account set -s $PSBoundParameters["$subscription"] 

# Function app and storage account names must be unique.
let "randomIdentifier=$RANDOM*$RANDOM"
location=eastus
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="deploy-function-app-with-function-github"
storage="msdocs$randomIdentifier"
skuStorage="Standard_LRS"
functionApp=mygithubfunc$randomIdentifier
functionsVersion="4"
runtime="node"
# Public GitHub repository containing an Azure Functions code project.
gitrepo=https://github.com/memasanz/OpenAIVectorSearchDemo

## Enable authenticated git deployment in your subscription when using a private repo. 
#token=<Replace with a GitHub access token when using a private repo.>
#az functionapp deployment source update-token \
#  --git-token $token

# Create a resource group.
echo "Creating $resourceGroup in ""$location""..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create a function app with source files deployed from the specified GitHub repo.
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storage --consumption-plan-location "$location" --resource-group $resourceGroup --deployment-source-url $gitrepo --deployment-source-branch main --functions-version $functionsVersion --runtime $runtime

# Connect to function application
#curl -s "https://${functionApp}.azurewebsites.net/api/httpexample?name=Azure"
#https://mmcogsearchcustomskillopenai.azurewebsites.net/api/Embeddings?code=