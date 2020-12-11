
<# Update the variables section appropriately for your environment.  
Info/examples provided - feedback appreciated if I can clarify further 
When you run the script you will get prompted for SQL credentials to 
connect to Azure SQL DB.  It will be used to connect and write to SQL table.  
You will also be prompted for credentials to connect to Azure portal that is 
used to connect to ADLS for storage info #>
$startTime = Get-Date
$SubscriptionId = '***Change This***'
$resourceGroupName = "***Change This***"
$resourceGroupLocation = "***Change This***" 
$azstoragename = "<storage account name>"
$containername = "<ADLS container name>" 
$SQLServer = "<Azure SQL DB full path name i.e. server.database.windows.net>"
$db = "<AzureSQLDB name>"

#any variables below do not need changed# 

$creds = Get-Credential
$plainTextPassword = $creds.GetNetworkCredential().Password

Connect-AzAccount
Select-AzSubscription -SubscriptionID $SubscriptionId

Write-Host "Authenticated to Azure " $startTime

#Check for existence of storage location specified
$ADLSCheck = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $azstoragename -ErrorAction SilentlyContinue
if(-not $ADLSCheck)
    {
    Write-Host "The ADLS storage '$azstoragename' doesn't exist so can't list files that don't exist"
    
    }
else 
    {
    Write-Host "The ADLS storage '$azstoragename' is there so let's grab file list"
    $ctx=(Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $azstoragename).Context
    $blobs = Get-AzStorageBlob -context $ctx -Container $containerName #| Select-Object -First 2
      foreach($blob in $blobs)  
        {  
            #Displays a list of the files to display
            write-host -Foregroundcolor Yellow $blob.Name  
            $blobname = $blob.Name 
            $qcd = "INSERT INTO [ADF].[ADLSFileListing]
           ([FileName]
           ,[BlobContainer]
           ,[ADFStarted])
     VALUES
           ('$blobname', '$containername', '$startTime')"
           # Will use variables above to write to Azure SQL DB with an insert statement
           # Adjust the query below to write to the table you want to write the file listing into 
            $qry2 = "INSERT INTO [ADF].[ADLSFileListing] ([FileName),[BlobContainer],[ADFStarted]) VALUES ( '$blobname' , '$containername', '$startTime')"
            $textqry = $qry2.ToString()
           # This query runs using sql authentication credentials prompted for earlier
           $DS = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db -Query $qcd -Username $sqluser -Password $plainTextPassword -MaxCharLength 50000 #-Verbose
         }
        }  
 