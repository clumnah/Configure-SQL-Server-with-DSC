Configuration ConfigureDatabaseMail
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SQLServerDSC

    Node $AllNodes.NodeName
    {
        # Set LCM to reboot if needed
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            RebootNodeIfNeeded = $true
        }
        SqlServerConfiguration 'EnableDatabaseMailXPs'
        {

            ServerName     = $Node.SQLServer
            InstanceName   = $Configuration.InstallSQL.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 1
            RestartService = $false
        }

        SqlServerDatabaseMail 'EnableDatabaseMail'
        {
            Ensure               = 'Present'
            ServerName           = $Node.SQLServer
            InstanceName         = $Configuration.InstallSQL.InstanceName
            AccountName          = $Configuration.InstallSQL.DatabaseMail.AccountName
            ProfileName          = $Configuration.InstallSQL.DatabaseMail.ProfileName
            EmailAddress         = $Configuration.InstallSQL.DatabaseMail.OriginatingAddress
            ReplyToAddress       = $Configuration.InstallSQL.DatabaseMail.ReplyToAddress
            DisplayName          = $Configuration.InstallSQL.DatabaseMail.MailServerName
            MailServerName       = $Configuration.InstallSQL.DatabaseMail.SMTPServer
            Description          = $Configuration.InstallSQL.DatabaseMail.ProfileDescription
            TcpPort              = $Configuration.InstallSQL.DatabaseMail.TcpPort

            PsDscRunAsCredential = $Configuration.InstallSQL.PsDscRunAsCredential
        }
    }
}