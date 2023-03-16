$GAModuleName = 'Microsoft.Graph.Authentication'
$GIDModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'
$IsConnectedToGraph = $false
$IsDomainnameProvidedResolvable = $false
$DefaultDelayTimeInSecs = 15
$GraphScopes = "User.Read.All", "Group.ReadWrite.All", "Domain.ReadWrite.All"
$IsGAModuleInstalled = [boolean](Get-InstalledModule  | ? { $_.Name -eq $GAModuleName })
$IsGIDModuleInstalled = [boolean](Get-InstalledModule | ? { $_.Name -eq $GIDModuleName})


if (Test-Path -Path C:\labfiles\companySettings.json){
$companySettings = Get-Content C:\labfiles\companySettings.json | ConvertFrom-Json
$companyname = $companySettings.CompanyPrefix
$DomainName = $companySettings.CompanyPrefix + ".onelearndns.com"
Write-Host -ForegroundColor Green "Your assigned company name: $companyname"
Write-Host -ForegroundColor Green "Your domain name: $DomainName"
}
else
{
Write-Warning "companySettings.json file was not found in c:\labfiles. Notify your instructor about this."
exit
} 


If ($IsGAModuleInstalled -eq $false){
    try

        {
            Write-Host 'Graph Authentication Module not installed.' -ForegroundColor White
            Write-Host 'Installing Graph Authentication Module'-ForegroundColor White
            Install-Module -Name $GAModuleName -Force
            $IsGAModuleInstalled = $true
            Write-Host 'Graph Authentication Module Installed' -ForegroundColor Green
        }

    catch

        {
            Write-Host 'Cannot install Graph Authenication Module, please install manually' -ForegroundColor Red
            Exit
        }
                }


If ($IsGIDModuleInstalled -eq $false){
  try

        {
            Write-Host 'Graph Identity DomainManagement Module not installed.' -ForegroundColor White
            Write-Host 'Installing Graph Identity DomainManagement Module'-ForegroundColor White
            Install-Module -Name $GIDModuleName -Force
            $IsGIDModuleInstalled = $true
            Write-Host 'Graph Identity DomainManagement Module Installed' -ForegroundColor Green
        }

    catch

        {
            Write-Host 'Cannot install Graph Identity DomainManagement Module, please install manually' -ForegroundColor Red
            Exit
        }
}



 if ( ([string]::IsNullOrWhiteSpace($DomainName)) -ne $true){               
    try

        {
            $DnsResolutionResult = [System.Net.Dns]::GetHostAddresses($DomainName)
            $IsDomainNameProvidedResolvable = $true
        }
               
    catch

        {
            $IsDomainNameProvidedResolvable = $false                
            Write-Host 'Error: Failed to resolve domain name provided $DomainName' -ForegroundColor Red          
        }
      
    try

        {
            Connect-MgGraph -Scopes $GraphScopes
            $IsConnectedToGraph = $true
        }

    catch

        {
            $IsConnectedToGraph = $false                
            Write-Host 'Error: Failed to connect to Graph!' -ForegroundColor Red         
        }    
                }

else

{
Write-Host 'Error: The assigned domain name cannot be empty, example: companyNNNNNN.onelearndns.com. Check setup and re-run script.' -ForegroundColor Red       
exit
} 

 if (($IsConnectedToGraph -eq $false) -OR ($IsDomainNameProvidedResolvable -eq $false)){
 Throw 'The vital pre-reqs have not been met.  Terminating...'
}

else

{
Write-Host 'All vital pre-reqs are met. Proceeding...' -ForegroundColor Green
}

$DomainExist = Get-MgDomain -DomainId $DomainName -ErrorAction SilentlyContinue

if ($DomainExist){
Write-Host "$DomainName already exists." -ForegroundColor Green
}
else
{
try    
    {
        Write-Host "Creating $DomainName in AAD" -ForegroundColor Green
        Import-Module Microsoft.Graph.Identity.DirectoryManagement
            $params = @{Id = $DomainName}
        $NewAADDomainCreationResult = New-MgDomain -BodyParameter $params
    }

catch

    {
        Write-Host 'Error: Failed to create the following AAD Domain: $DomainName' + $Error[0].Exception -ForegroundColor Red
    } 
        }

Get-MgDomainVerificationDnsRecord -DomainId $DomainName | Where {$_.RecordType -eq 'Txt'} | select additionalproperties | ConvertTo-Json | out-file c:\temp\$DomainName.json

$textrecord = Get-Content C:\temp\$DomainName.json | ConvertFrom-Json
Add-DnsServerResourceRecord -ZoneName $DomainName -Txt -Name '@' -DescriptiveText $textrecord.additionalproperties.text

Confirm-MgDomain -DomainId $DomainName

$VerifiedDomain = (Get-MgDomain -DomainId $DomainName).IsVerified
If ($VerifiedDomain) {Write-Host "$DomainName has been verified." -ForegroundColor Green}
else
{
Write-Warning "$DomainName was not able to be verified.  Notify your instructor."
}
Disconnect-MgGraph