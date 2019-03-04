Configuration LocalAdministrators
{
    Import-DscResource -Module PSDesiredStateConfiguration
    Node $AllNodes.NodeName
    {
        Group LocalAdministrators 
        {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= $Configuration.InstallSQL.SQLSysAdminAccounts
            Credential = $Node.PsDscRunAsCredential
            PsDscRunAsCredential = $Node.PsDscRunAsCredential
        }
    }
}

