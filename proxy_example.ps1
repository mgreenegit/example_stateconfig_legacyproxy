# The values in this section will need to be updated with the uri/key from Azure Automation
$MetaParams = @{
    RegistrationUrl = 'REPLACE_WITH_SERVICE_URI';
    RegistrationKey = 'REPLACE_WITH_SERVICE_KEY';
}
# The values in this section will need to be updated with the IP:PORT of your proxy server
$ProxyParams = @{
    ProxyServer             = 'REPLACE_WITH_PROXY_IP:PORT';
    ProxyServerExceptions   = '';
}

Install-PackageProvider -Name Nuget -Force
Install-Module NetworkingDsc -Force

Configuration Proxy
{
param(
    [Parameter(Mandatory=$true)]
    [string]$ProxyServer,
    [string]$ProxyServerExceptions
)
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        ProxySettings ManualProxy
        {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Present'
            EnableAutoDetection     = $false
            EnableAutoConfiguration = $false
            EnableManualProxy       = $true
            ProxyServer             = $ProxyServer
            ProxyServerExceptions   = $ProxyServerExceptions
            ProxyServerBypassLocal  = $true
        }
    }
}

Proxy @ProxyParams -out c:\ProgramData\StateConfig\Proxy
Publish-DscConfiguration -Path c:\ProgramData\StateConfig\Proxy -Verbose

[DscLocalConfigurationManager()]
Configuration StateConfigurationLegacyProxy
{
param(
    [Parameter(Mandatory=$true)]
    [string]$RegistrationUrl,
    [Parameter(Mandatory=$true)]
    [string]$RegistrationKey
)
        Settings
        {
            RefreshFrequencyMins            = 30;
            RefreshMode                     = 'PULL';
            ConfigurationMode               = 'ApplyAndMonitor';
            AllowModuleOverwrite            = $false;
            RebootNodeIfNeeded              = $false;
            ConfigurationModeFrequencyMins  = 15;
        }
        ConfigurationRepositoryWeb StateConfiguration
        {
            ServerURL                       = $RegistrationUrl
            RegistrationKey                 = $RegistrationKey
            ConfigurationNames              = ''
        }

        PartialConfiguration Proxy
        {
            Description                     = 'http_proxy'
            RefreshMode                     = 'Push'
        }
        
        PartialConfiguration PullService
        {
            Description                     = 'azure_service_registration'
            ConfigurationSource             = @('[ConfigurationRepositoryWeb]StateConfiguration')
            RefreshMode                     = 'Pull'
            DependsOn                       = '[PartialConfiguration]Proxy'
        }

}

StateConfigurationLegacyProxy @MetaParams -out c:\ProgramData\StateConfig\Registration
Set-DscLocalConfigurationManager -Path c:\ProgramData\StateConfig\Registration -Verbose

Remove-Item -Path c:\ProgramData\StateConfig -Recurse -Force
