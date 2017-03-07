$Computers = 'sql2016n1'
$OutputPath = 'C:\Users\chris.LUMNAH\sqlserversetup'
$ConfigurationFile = "SQLServerConfiguration.json"
$Configuration = (Get-Content $ConfigurationFile) -join "`n"  | ConvertFrom-Json
Clear-Host
Import-Module -Name SQLServer -Force -DisableNameChecking
Import-Module -Name .\ConfigureSQLServer.psm1 -Force
if (-not (Test-IsAdmin))
{
    Write-Host "This script must be " -ForegroundColor White -NoNewline; write-host  "Run As Administrator" -ForegroundColor Yellow
    write-Host "Please restart this script from an elevated Powershell window"
}
else
{
    Configuration SQLServerInstall
    {
        param
        (
            [string]$ComputerName,
            [int32]$MAXDOP,
            [int32]$MAXMemory
        )
        Import-DscResource –Module PSDesiredStateConfiguration
        Import-DscResource -Module xSQLServer
        Import-DscResource -Module SecurityPolicyDsc
        Import-DscResource -Module xPendingReboot


        Node $ComputerName
        {
            WindowsFeature NET-Framework-Core
            {
                Name = "NET-Framework-Core"
                Ensure = "Present"
                IncludeAllSubFeature = $true
            }
            xSqlServerSetup InstallSQL
            {
                DependsOn = '[WindowsFeature]NET-Framework-Core'
                Features = $Configuration.InstallSQL.Features
                InstanceName = $Configuration.InstallSQL.InstanceName
                SQLCollation = $Configuration.InstallSQL.SQLCollation
                SQLSysAdminAccounts = $Configuration.InstallSQL.SQLSysAdminAccounts
                InstallSQLDataDir = $Configuration.InstallSQL.InstallSQLDataDir
                SQLUserDBDir = $Configuration.InstallSQL.SQLUserDBDir
                SQLUserDBLogDir = $Configuration.InstallSQL.SQLUserDBLogDir
                SQLTempDBDir = $Configuration.InstallSQL.SQLTempDBDir
                SQLTempDBLogDir = $Configuration.InstallSQL.SQLTempDBLogDir
                SQLBackupDir = $Configuration.InstallSQL.SQLBackupDir

                SourcePath = $Configuration.InstallSQL.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }
            xSQLServerNetwork ConfigureSQLNetwork
            {
                DependsOn = "[xSqlServerSetup]InstallSQL"
                InstanceName = $Configuration.InstallSQL.InstanceName
                ProtocolName = "tcp"
                IsEnabled = $true
                TCPPort = 1433
                RestartService = $true
            }
            xSQLServerConfiguration DisableRemoveAccess
            {
                SQLServer = $ComputerName
                SQLInstanceName = $Configuration.InstallSQL.InstanceName
                DependsOn = "[xSqlServerSetup]InstallSQL"
                OptionName = "Remote access"
                OptionValue = 0
            }
            UserRightsAssignment PerformVolumeMaintenanceTasks
            {
                Policy = "Perform_volume_maintenance_tasks"
                Identity = "Builtin\Administrators"
            }
            UserRightsAssignment LockPagesInMemory
            {
                Policy = "Lock_pages_in_memory"
                Identity = "Builtin\Administrators"
            }
            xPendingReboot PendingReboot
            {
                Name = $ComputerName
            }
            LocalConfigurationManager
            {
                RebootNodeIfNeeded = $True
            } 
            xSQLServerAlwaysOnService EnableAlwaysOn
            {
                SQLServer = $ComputerName
                SQLInstanceName = $Configuration.InstallSQL.InstanceName
                DependsOn = "[xSqlServerSetup]InstallSQL"
                Ensure = "Present"
            }
            xSQLServerMaxDop SetMAXDOP
            {
                SQLInstanceName = $Configuration.InstallSQL.InstanceName
                DependsOn = "[xSqlServerSetup]InstallSQL"
                MaxDop = $MAXDOP
            }
            xSQLServerMemory SetMAXDOP
            {
                SQLInstanceName = $Configuration.InstallSQL.InstanceName
                DependsOn = "[xSqlServerSetup]InstallSQL"
                MaxMemory = $MAXMemory
                DynamicAlloc = $False
            }
        }
    }



    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName = "*"
                PSDscAllowPlainTextPassword = $true
                PSDscAllowDomainUser =$true
                InstallerServiceAccount = Get-Credential -UserName lumnah\chris -Message "Credentials to Install SQL Server"
            }
        )
    }


    ForEach ($Computer in $Computers)
    {
        $CpuCount = 0
        $MaxMemory = [Math]::Truncate((Get-ServerMemory -ServerName $Computer) * .8)
        $CPUCount = Get-ProcessorCount -ServerName $Computer
        if ($CPUCount -gt 8) { $CPUCount = 8 }
        $CPUCount
        $ConfigurationData.AllNodes += @{
            NodeName = $Computer
        }        
        $Destination = "\\"+$Computer+"\\c$\Program Files\WindowsPowerShell\Modules"
        Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\xSQLServer' -Destination $Destination -Recurse -Force
        Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\SecurityPolicyDsc' -Destination $Destination -Recurse -Force
        Copy-Item 'C:\Program Files\WindowsPowerShell\Modules\xPendingReboot' -Destination $Destination -Recurse -Force
        SQLServerInstall -ConfigurationData $ConfigurationData -OutputPath $OutputPath -ComputerName $Computer -MAXDOP $CPUCount -MAXMemory $MAXMemory
    }


    
    #Push################################
    foreach($Computer in $Computers)
    {

        Start-DscConfiguration -ComputerName $Computer -Path $OutputPath -Verbose -Wait -Force
        New-SQLFirewallRule -ServerName $Computer
        Set-ModelDatabaseSettings -ServerName $Computer -InstanceName $Configuration.InstallSQL.InstanceName
        Set-TempdbConfiguration -ServerName $Computer -InstanceName $Configuration.InstallSQL.InstanceName
        #if ($InstanceName -ne 'MSSQLSERVER'){Disable-SQLService -ServerName $Computer -InstanceName $Configuration.InstallSQL.InstanceName -ServiceName "SqlBrowser"}
        #Revoke Access to Public
    }
    
}