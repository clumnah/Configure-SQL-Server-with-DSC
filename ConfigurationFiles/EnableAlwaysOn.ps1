Configuration EnableAlwaysOn
{
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module SQLServerDSC
    Node $AllNodes.NodeName
    {
        SqlAlwaysOnService 'EnableAlwaysOn'
        {
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = $Configuration.InstallSQL.InstanceName
            RestartTimeout       = 120
            PsDscRunAsCredential = $Node.PsDscRunAsCredential
        }
    }
}