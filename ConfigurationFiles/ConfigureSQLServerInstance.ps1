Configuration ConfigureSQLServerInstance
{
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module SQLServerDSC
    Node $AllNodes.NodeName
    {
        SqlServerMaxDop Set_SQLServerMaxDop_ToAuto
        {
            Ensure                  = 'Present'
            DynamicAlloc            = $true
            ServerName              = $Node.SQLServer
            InstanceName            = $Configuration.InstallSQL.InstanceName
            PsDscRunAsCredential    = $Node.PsDscRunAsCredential
            ProcessOnlyOnActiveNode = $true
        }
        SqlServerMemory Set_SQLServerMaxMemory_ToAuto
        {
            Ensure                  = 'Present'
            DynamicAlloc            = $true
            ServerName              = $Node.SQLServer
            InstanceName            = $Configuration.InstallSQL.InstanceName
            PsDscRunAsCredential    = $Node.PsDscRunAsCredential
            ProcessOnlyOnActiveNode = $true
        }
        SqlServerNetwork ChangeTcpIpOnDefaultInstance
        {
            ServerName           = $Node.SQLServer
            InstanceName         = $Configuration.InstallSQL.InstanceName
            ProtocolName         = 'Tcp'
            IsEnabled            = $true
            TCPDynamicPort       = $false
            TCPPort              = 1433
            RestartService       = $true
            PsDscRunAsCredential = $Node.PsDscRunAsCredential
        }
        SqlWindowsFirewall Create_FirewallRules_For_SQL
        {
            Ensure               = 'Present'
            Features             = $Configuration.InstallSQL.Features
            InstanceName         = $Configuration.InstallSQL.InstanceName
            SourcePath           = "$($Configuration.InstallSQL.Paths.$($SQLVersion).SourcePath)"
            PsDscRunAsCredential = $Node.PsDscRunAsCredential
        }
    }
}