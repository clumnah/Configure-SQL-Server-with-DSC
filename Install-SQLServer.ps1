<#
.SYNOPSIS
Install-SQLServer.ps1 will install and configure SQL Server on a remote machine

.DESCRIPTION
Install-SQLServer.ps1 will install and configure SQL Server on a remote machine using Desired State Configuration (DSC). I use the standard DSC modules available 
from Microsoft and the Powershell Gallery. Microsoft does change this module each month as they make enhancements so be sure to teste each time you update your 
DSC modules. 

.PARAMETER ComputerName
Computer to install SQL Server On

.PARAMETER FCI
Switch to denote that this will be an Failover Cluster Instance installation

.PARAMETER NodeRole
Tells script that ComputerName is either the Primary or the Secondary Node. 

.PARAMETER FailoverClusterNetworkName
The Virtual Name you give the new Clustered Instance of SQL Server. This will be how you access the SQL Server remotely. 

.PARAMETER FailoverClusterGroupName
This is the name that will show up in Failover Cluster Manager to help you identify the resources allocated to this instance of SQL Server

.PARAMETER FailoverClusterIPAddress
IP Address given that maps to FailoverClusterNetworkName

.PARAMETER StandAlone
Switch to denote that this will be a stand alone instance of SQL server

.PARAMETER EnableAlwaysOn
Switch to denote that AlwaysOn should be turned on after installation is complete

.PARAMETER SQLVersion
Version of SQL Server. Currently supports SQL server 2008R2-2017

.EXAMPLE
Install SQL Server on a primary node of an FCI configuration
.\Install-SQLServer.ps1 `
    -ComputerName cl-sql2012-1a `
    -fci `
    -NodeRole primary `
    -FailoverClusterNetworkName clsql2012c1 `
    -FailoverClusterIPAddress 172.21.11.97 `
    -SQLVersion 2012

.EXAMPLE
Install SQL Server on a secondary node of an FCI configuration
.\Install-SQLServer.ps1 `
    -ComputerName cl-sql2012-1b `
    -fci `
    -NodeRole secondary `
    -FailoverClusterNetworkName clsql2012c1 `
    -FailoverClusterIPAddress 172.21.11.97 `
    -SQLVersion 2012   

.EXAMPLE
Install SQL Server on a single standalone server
.\Install-SQLServer.ps1 `
    -ComputerName cl-sql2012-1a `
    -StandAlone `
    -SQLVersion 2012

.EXAMPLE
Install SQL Server on a single standalone server with Always On Enabled
.\Install-SQLServer.ps1 `
    -ComputerName cl-sql2012-1a `
    -StandAlone `
    -SQLVersion 2012 `
    -EnableAlwaysOn

.NOTES
Name:               Install SQL Server
    Created:            1/03/2019
    Author:             Chris Lumnah
    Execution Process:
    At the time of this writing, SQLServerDSC was at 12.1.0.0. Future versions of this module could have breaking changes and will need to be retested

    To properly execute this process, there should be a JSON file called SQLServerConfiguration.json which contains all of the parameters required for a 
    installation of SQL Server to happen. When reading the JSON file, it will mirror the parameters listed in a Configuration.ini that is created during 
    installation time, or one you can create for an unattended installation. This file should be modified first to match values in your environment.

    The script has the ability to also install any Service Packs and/or Cumulative Updates, provided the update files are placed into a folder listed in the
    UpdateSource field in the JSON file. 

    DatabaseMail can also be configured, but is disabled at this time, as this is not a feature we are using. 
    
    When you run the script, it will ask you for credentials. The credentials required are as followed

        -Credential to run the installation on the remote machine
        -Credential to access the installation media
        -Credential for the SQL Server Service Account
        -Credential for the SQL Server Agent Service Account
        -Credential for the sa password



#>
#Requires -Version 4
#Requires -Modules PSDesiredStateConfiguration
#Requires -Modules SQLServerDSC 

[CmdletBinding(DefaultParametersetName="StandAlone")] 
param
(
    # Computer name to install SQL Server On
    [Parameter(Mandatory=$true)]
    [String]$ComputerName,

    # Will this be a Failover Cluster Instance Install?
    [Parameter(Mandatory=$False, ParameterSetName="FCI")]
    [Switch]$FCI,

    # If this is an FCI install, then choose between Primary or Secondary
    [Parameter(Mandatory=$true, ParameterSetName="FCI")]
    [ValidateSet("Primary", "Secondary")]
    [String]$NodeRole,    
    
    # What is the Cluster Network Name to use wtih the new clustered instance of SQL?
    [Parameter(Mandatory=$true, ParameterSetName="FCI")]
    [String]$FailoverClusterNetworkName,

    # What is the Cluster Network Name to use wtih the new clustered instance of SQL?
    [Parameter(Mandatory=$false, ParameterSetName="FCI")]
    [String]$FailoverClusterGroupName = "SQL Server (MSSQLSERVER)",

    # What is the IP Address to use wtih the new clustered instance of SQL?
    [Parameter(Mandatory=$true, ParameterSetName="FCI")]
    [String]$FailoverClusterIPAddress ,

    # Will this be a Stand Alone Install?
    [Parameter(Mandatory=$False, ParameterSetName="StandAlone")]
    [Switch]$StandAlone,

    # Will this be a Stand Alone Install?
    [Parameter(Mandatory=$False, ParameterSetName="StandAlone")]
    [Switch]$EnableAlwaysOn,

    # What version of SQL are you installing??
    [Parameter(Mandatory=$True)]
    [ValidateSet("2008R2", "2012", "2014", "2016", "2017")]
    [String]$SQLVersion
)
Clear-Host
$OutputPath = '.\MOF'
$ConfigurationFile = "SQLServerConfiguration.json"
$Configuration = (Get-Content $ConfigurationFile) -join "`n"  | ConvertFrom-Json

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser =$true
            PsDscRunAsCredential = Get-Credential -UserName "$($env:UserDomain)\$($env:UserName)" -Message "Credentials to Install SQL Server"
            SourceCredential = Get-Credential -UserName "$($env:UserDomain)\$($env:UserName)" -Message "Credentials to access installation media"
            SQLSvcAccount  = Get-Credential -UserName $Configuration.InstallSQL.SQLSvcAccount -Message "Credentials to run the SQL Server Service "
            AgtSvcAccount =  Get-Credential -UserName $Configuration.InstallSQL.AgtSvcAccount -Message "Credentials used to run the SQL Agent Service"
            SAPwd  =  Get-Credential -UserName $Configuration.InstallSQL.SAPwd  -Message "Set the password to the SA account" 
        }
    )
}

#Push Modules to server to install SQL Server on. 
$Destination = "\\" +$ComputerName +"\\c$\Program Files\WindowsPowerShell\Modules"
Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\SQLServerDSC' -Destination $Destination -Recurse -Force 
Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\SecurityPolicyDsc' -Destination $Destination -Recurse -Force 

if ($StandAlone)
{        
    Write-Host "Import Stand Alone Instance Configuration"
    . .\ConfigurationFiles\StandAloneInstance.ps1
    
    $ConfigurationData.AllNodes += @{
        NodeName = $ComputerName
        SQLServer = $ComputerName
    }        
    StandAloneInstance -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
}

if ($FCI) 
{
    $ConfigurationData.AllNodes += @{
        NodeName = $ComputerName
        Role = $NodeRole
        FailoverClusterIPAddress = $FailoverClusterIPAddress
        FailoverClusterNetworkName = $FailoverClusterNetworkName
        FailoverClusterGroupName = $FailoverClusterGroupName
        SQLServer = $FailoverClusterNetworkName
    }  
    If ($NodeRole -eq "Primary")
    {
        Write-Host "Import FCI Primary Node Configuration"
        . .\ConfigurationFiles\FCIPrimaryNode.ps1
        FCIPrimaryNode -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
    }  
    else 
    {
        Write-Host "Import FCI Secondary Node Configuration"
        . .\ConfigurationFiles\FCISecondaryNode.ps1
        FCISecondaryNode -ConfigurationData $ConfigurationData -OutputPath $OutputPath     
    }
}

#Go Install SQL Server
Start-DscConfiguration -ComputerName $ComputerName -Path $OutputPath -Verbose -Wait -Force

#Configure the local admins
. .\ConfigurationFiles\LocalAdministrators.ps1
LocalAdministrators -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
Start-DscConfiguration  -ComputerName $ComputerName -Path $OutputPath -Verbose -Wait -Force

#Now go Configure the instance
If ($NodeRole -eq "Primary" -or ($Standalone))
{
    #Configure the Instane
    . .\ConfigurationFiles\ConfigureSQLServerInstance.ps1
    ConfigureSQLServerInstance -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
    Start-DscConfiguration  -ComputerName $ComputerName -Path $OutputPath -Verbose -Wait -Force

    #This will need to be tested in a later version of the module. As of Version 12, this still does not work
    #. .\ConfigurationFiles\CreateWindowsFirewallRules.ps1
    #CreateWindowsFirewallRules -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
    #Start-DscConfiguration  -ComputerName $ComputerName -Path $OutputPath -Verbose -Wait -Force

}

if ($EnableAlwaysOn)
{
    . .\ConfigurationFiles\EnableAlwaysOn.ps1 
    EnableAlwaysOn -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
    Start-DscConfiguration  -ComputerName $ComputerName -Path $OutputPath -Verbose -Wait -Force
}

#Enable this section if you want to configure database mail. 
#. .\ConfigurationFiles\ConfigureDatabaseMail.ps1 
#ConfigureDatabaseMail -ConfigurationData $ConfigurationData -OutputPath $OutputPath 
#Start-DscConfiguration  -ComputerName $ComputerName -Path $OutputPath -Verbose -Wait -Force

