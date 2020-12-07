# Configure-SQL-Server-DSC

To get started watch these videos on how DSC works https://mva.microsoft.com/en-us/training-courses/getting-started-with-powershell-desired-state-configuration-dsc--8672?l=ZwHuclG1_2504984382

The DSC modules used in this set of scripts can be found on github or on http://www.powershellgallery.com/

# How to use
## JSON Files
All configuration of the installation of SQL Server is controlled via JSON files that are created for either a Stand Alone Instance or a Failover Clustered Instance. The repective JSON files have parameters in them that pertain to that type of installation type

The JSON is setup to mirror the parameter structure of Configuration.ini. That parameter structure is then used in the SQLServerDSC Desired State Powershell module. The values in the file can be changed to match your environment. 

SQLServerConfigurationStandAlone.json
SQLServerConfigurationFCI.json

