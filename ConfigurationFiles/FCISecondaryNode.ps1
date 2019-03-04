Configuration FCISecondaryNode
{
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module SQLServerDSC

    Node $AllNodes.NodeName
    {
        # Set LCM to reboot if needed
        LocalConfigurationManager
        {
            DebugMode = 'ForceModuleImport'
            RebootNodeIfNeeded = $true
        }

        WindowsFeature NET-Framework-Core
        {
            Name = 'NET-Framework-Core'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }
        SqlSetup Install_SQL
        {
            PsDscRunAsCredential = $Node.PsDscRunAsCredential
            DependsOn = '[WindowsFeature]NET-Framework-Core'
            Action =  "AddNode"
            UpdateEnabled = $Configuration.InstallSQL.UpdateEnabled
            UpdateSource = "$($Configuration.InstallSQL.Paths.$($SQLVersion).UpdateSource)"
            Features = $Configuration.InstallSQL.Features
            InstanceName = $Configuration.InstallSQL.InstanceName

            InstallSharedDir = $Configuration.InstallSQL.InstallSharedDir
            InstallSharedWOWDir = $Configuration.InstallSQL.InstallSharedWOWDir
            InstanceDir = $Configuration.InstallSQL.InstanceDir

            InstallSQLDataDir = $Configuration.InstallSQL.InstallSQLDataDir
            SQLUserDBDir = $Configuration.InstallSQL.SQLUserDBDir
            SQLUserDBLogDir = $Configuration.InstallSQL.SQLUserDBLogDir
            SQLTempDBDir = $Configuration.InstallSQL.SQLTempDBDir
            SQLTempDBLogDir = $Configuration.InstallSQL.SQLTempDBLogDir
            SQLBackupDir = $Configuration.InstallSQL.SQLBackupDir
            
            AgtSvcAccount = $Node.AgtSvcAccount
            SQLSvcAccount = $Node.SQLSvcAccount

            SQLCollation = $Configuration.InstallSQL.SQLCollation
        
            SQLSysAdminAccounts = $Configuration.InstallSQL.SQLSysAdminAccounts
        
            SourcePath = "$($Configuration.InstallSQL.Paths.$($SQLVersion).SourcePath)"
            SourceCredential = $Node.SourceCredential

            FailoverClusterGroupName = $Node.FailoverClusterGroupName
            FailoverClusterIPAddress = $Node.FailoverClusterIPAddress
            FailoverClusterNetworkName = $Node.FailoverClusterNetworkName
        }
    }
}