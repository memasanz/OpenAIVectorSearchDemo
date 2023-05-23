
#https://github.com/kubasiak/Azure-Cognitive-Search-Azure-OpenAI-Accelerator/blob/main/01-Load-Data-ACogSearch.ipynb

param($subscription, $tenantid )

$Script:args=""
write-host "Num Args: " $PSBoundParameters.Keys.Count
foreach ($key in $PSBoundParameters.keys) {
    $Script:args+= "`$$key=" + $PSBoundParameters["$key"] + "  "
}
write-host $Script:args

Write-Host "subscription: $subscription"
write-host $PSBoundParameters["$subscription"]


az account set --subscription $subscription

$TokenSet = @{
    U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    L = [Char[]]'abcdefghijklmnopqrstuvwxyz'
    N = [Char[]]'0123456789'
    S = [Char[]]'!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'
}

$Lower = Get-Random -Count 5 -InputObject $TokenSet.L
$StringSet = $Lower
$Myrandom = (Get-Random -Count 5 -InputObject $StringSet) -join ''

Write-Host "Random: $Myrandom"

# # Function app and storage account names must be unique.
$randomIdentifier=$Myrandom
$location="eastus"
$resourceGroup="msdocs-azure-functions-rg-" + $randomIdentifier
write-host $resourceGroup

$tag="deploy-function-app-with-function-github"
$storage="msdocs$randomIdentifier"
$skuStorage="Standard_LRS"
$functionApp="mygithubfunc" + $randomIdentifier
$functionsVersion="4"
$runtime="node"
# # # Public GitHub repository containing an Azure Functions code project.
#$gitrepo="gitrepo=https://github.com/Azure-Samples/functions-quickstart-javascript"

#$gitrepo="gitrepo=https://github.com/memasanz/OpenAIVectorSearchDemo/Code/AzureFunction"

$gitrepo="gitrepo=https://github.com/memasanz/deleteme2"

# ## Enable authenticated git deployment in your subscription when using a private repo. 
# #token=<Replace with a GitHub access token when using a private repo.>
# #az functionapp deployment source update-token \
# #  --git-token $token

# # Create a resource group.
echo "Creating $resourceGroup in ""$location""..."
az group create --name $resourceGroup --location "$location" --tags $tag

# # Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# # Create a function app with source files deployed from the specified GitHub repo.
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storage --consumption-plan-location "$location" --resource-group $resourceGroup --deployment-source-url $gitrepo --deployment-source-branch main --functions-version $functionsVersion --runtime $runtime
