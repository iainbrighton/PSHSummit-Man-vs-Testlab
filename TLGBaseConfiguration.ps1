Configuration TLGBaseConfiguration {
    param (
        [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Username 'Administrator' -Message 'Enter Domain administrator username/password.')
    )
    Import-DscResource -Module PSDesiredStateConfiguration;
    Import-DscResource -Module xComputerManagement;         ## https://github.com/PowerShell/xComputerManagement/tree/master
    Import-DscResource -Module xNetworking;                 ## https://github.com/PowerShell/xNetworking/tree/master
    Import-DscResource -Module xActiveDirectory;            ## https://github.com/PowerShell/xActiveDirectory/tree/master
    Import-DscResource -Module xSmbShare;                   ## https://github.com/PowerShell/xSmbShare/tree/master
    Import-DscResource -Module xDHCPServer;                 ## REQUIRES: https://github.com/iainbrighton/xDhcpServer (due to xDhcpServerAuthorization)
    Import-DscResource -Module xDNSServer;                  ## REQUIRES: https://github.com/iainbrighton/xDnsServer/tree/TestLabGuides (due to xDnsServerPrimaryZone)

    node $AllNodes.Where({$_.Role -notin 'CLIENT'}).NodeName {
        ## CLIENT1 is set to DHCP!
        xIPAddress 'IPAddress_Primary' {
            IPAddress      = $node.IPAddress;
            InterfaceAlias = $node.InterfaceAlias;
            DefaultGateway = $node.DefaultGateway;
            SubnetMask     = $node.SubnetMask;
            AddressFamily  = $node.AddressFamily;
        }

        xDnsServerAddress 'DNSClient_Primary' {
            Address        = $node.DnsServerAddress;
            InterfaceAlias = $node.InterfaceAlias;
            AddressFamily  = $node.AddressFamily;
        }
    }

    node $AllNodes.Where({$_.IPAddress2}).NodeName {
        xIPAddress 'IPAddress_Secondary' {
            IPAddress      = $node.IPAddress2;
            InterfaceAlias = $node.InterfaceAlias2;
            DefaultGateway = $node.DefaultGateway2;
            SubnetMask     = $node.SubnetMask2;
            AddressFamily  = $node.AddressFamily2;
        }

        xDnsServerAddress 'DNSClient_Secondary' {
            Address        = $node.DnsServerAddress2;
            InterfaceAlias = $node.InterfaceAlias2;
            AddressFamily  = $node.AddressFamily2;
        } 
    }

    node $AllNodes.Where({$true}).NodeName {
        LocalConfigurationManager {
            RebootNodeIfNeeded   = $true;
            AllowModuleOverwrite = $true;
            ConfigurationMode = 'ApplyAndMonitor';
            CertificateID = $node.Thumbprint;
        }
        
        xFirewall 'Firewall_FPS-ICMP4-ERQ-In' {
            Name = 'FPS-ICMP4-ERQ-In';
            DisplayName = 'File and Printer Sharing (Echo Request - ICMPv4-In)';
            DisplayGroup = 'File and Printer Sharing';
            Description = 'Echo request messages are sent as ping requests to other nodes.';
            Direction = 'Inbound';
            Access = 'Allow';
            State = 'Enabled';
            Profile = 'Any';
        }
    } #end nodes ALL
  
    node $AllNodes.Where({$_.Role -in 'DC'}).NodeName {
        ## Flip credential into username@domain.com
        $domainCredential = New-Object System.Management.Automation.PSCredential("$($Credential.UserName)@$($node.DomainName)", $Credential.Password);

        xComputer 'Computer_Hostname' {
            Name = $node.NodeName;
        }
        
        ## Hack to fix DependsOn with hypens "bug" :(
        foreach ($feature in @(
                'AD-Domain-Services',
                'GPMC',
                'RSAT-AD-Tools'
            )) {
            WindowsFeature $feature.Replace('-','') {
                Ensure = 'Present';
                Name = $feature;
                IncludeAllSubFeature = $true;
                DependsOn = '[xComputer]Computer_Hostname';
            }
        }
        
        xADDomain 'ADDomain_corp_contoso_com' {
            DomainName = $node.DomainName;
            SafemodeAdministratorPassword = $Credential;
            DomainAdministratorCredential = $Credential;
            DependsOn = '[WindowsFeature]ADDomainServices';
        }

        foreach ($feature in @(
                'DHCP',
                'RSAT-DHCP'
            )) {
            WindowsFeature $feature.Replace('-','') {
                Ensure = 'Present';
                Name = $feature;
                IncludeAllSubFeature = $true;
                DependsOn = '[xADDomain]ADDomain_corp_contoso_com';
            }
        }

        xDhcpServerAuthorization 'DHCP_Authorization' {
            Ensure = 'Present';
            DependsOn = '[WindowsFeature]DHCP';
        }
        
        xDhcpServerScope 'DhcpScope_10_0_0_0' {
            Name = 'Corpnet';
            IPStartRange = '10.0.0.100';
            IPEndRange = '10.0.0.200';
            SubnetMask = '255.255.255.0';
            LeaseDuration = '00:08:00';
            State = 'Active';
            AddressFamily = 'IPv4';
            DependsOn = '[WindowsFeature]DHCP';
        }

        xDhcpServerOption 'DhcpScope_10_0_0_0_Option' {
            ScopeID = '10.0.0.0';
            DnsDomain = 'corp.contoso.com';
            DnsServerIPAddress = '10.0.0.1';
            Router = '10.0.0.2';
            AddressFamily = 'IPv4';
            DependsOn = '[xDhcpServerScope]DhcpScope_10_0_0_0';
        }

        xDnsServerPrimaryZone 'DNS_Zone_0_0_10_InAddr_Arpa' {
            Name = '0.0.10.in-addr.arpa';
            ZoneFile = '0.0.10.in-addr.arpa.dns'
            DependsOn = '[xADDomain]ADDomain_corp_contoso_com';
        }
        
        xADUser 'ADUser_User1' { 
            DomainName = $node.DomainName;
            DomainAdministratorCredential = $domainCredential;
            UserName = 'User1';
            Password = $Credential;
            Ensure = 'Present';
            DependsOn = '[xADDomain]ADDomain_corp_contoso_com';
        }
    } #end nodes DC
    
    node $AllNodes.Where({$_.Role -in 'APP','EDGE','CLIENT'}).NodeName {
        ## Flip credential into username@domain.com
        $domainCredential = New-Object System.Management.Automation.PSCredential("$($Credential.UserName)@$($node.DomainName)", $Credential.Password);

        xComputer 'DomainMembership' {
            Name = $node.NodeName;
            DomainName = $node.DomainName;
            Credential = $domainCredential;
        }
    } #end nodes DomainJoined
    
    node $AllNodes.Where({$_.Role -in 'APP'}).NodeName {
        ## Flip credential into username@domain.com
        $domainCredential = New-Object System.Management.Automation.PSCredential("$($Credential.UserName)@$($node.DomainName)", $Credential.Password);
        
        foreach ($feature in @(
                'Web-Default-Doc',
                'Web-Dir-Browsing',
                'Web-Http-Errors',
                'Web-Static-Content',
                'Web-Http-Logging',
                'Web-Stat-Compression',
                'Web-Filtering',
                'Web-Mgmt-Tools',
                'Web-Mgmt-Console')) {
            WindowsFeature $feature.Replace('-','') {
                Ensure = 'Present';
                Name = $feature;
                IncludeAllSubFeature = $true;
                DependsOn = '[xComputer]DomainMembership';
            }
        }

        File 'File_FilesFolder' {
            DestinationPath = 'C:\Files';
            Type = 'Directory';
        }

        File 'File_Example_Txt' {
            DestinationPath = 'C:\Files\Example.txt'
            Type = 'File';
            Contents = 'This is a shared file.';
            DependsOn = '[File]File_FilesFolder';
        }

        xSmbShare 'xSMBShare_Files' {
            Name = 'Files';
            Path = 'C:\Files';
            ChangeAccess = 'BUILTIN\Administrators';
            DependsOn = '[File]File_FilesFolder';
            Ensure = 'Present';
        }
    } #end nodes APP

    node $AllNodes.Where({$_.Role -in 'INET'}).NodeName {
        
        xComputer 'Hostname' {
            Name = $node.NodeName;
        }

        foreach ($feature in @(
                'Web-Default-Doc',
                'Web-Dir-Browsing',
                'Web-Http-Errors',
                'Web-Static-Content',
                'Web-Http-Logging',
                'Web-Stat-Compression',
                'Web-Filtering',
                'Web-Mgmt-Tools',
                'Web-Mgmt-Console',
                'DNS',
                'DHCP',
                'RSAT-DNS-Server',
                'RSAT-DHCP')) {
            WindowsFeature $feature.Replace('-','') {
                Ensure = 'Present';
                Name = $feature;
                IncludeAllSubFeature = $true;
            }
        }

        xDhcpServerScope 'DHCP_Scope_137_107_0_0' {
            Name = 'Internet';
            IPStartRange = '131.107.0.100';
            IPEndRange = '131.107.0.150';
            SubnetMask = '255.255.255.0';
            LeaseDuration = '00:08:00';
            State = 'Active';
            AddressFamily = 'IPv4';
            DependsOn = '[WindowsFeature]DHCP';
        }

        xDhcpServerOption 'DhcpScope137_107_0_0_Option' {
            ScopeID = '131.107.0.0';
            DnsDomain = 'isp.example.com';
            DnsServerIPAddress = '131.107.0.1';
            Router = '131.107.0.1';
            AddressFamily = 'IPv4';
            DependsOn = '[xDhcpServerScope]DHCP_Scope_137_107_0_0';
        }

        File 'NCSI_txt' {
            DestinationPath = 'C:\inetpub\wwwroot\ncsi.txt';
            Type = 'File';
            Contents = 'Microsoft NCSI';
            DependsOn = '[WindowsFeature]WebDefaultDoc';
        }

        xDnsServerPrimaryZone 'DNS_Zone_contoso_com' {
            Name = 'contoso.com';
            ZoneFile = 'contoso.com.dns'
            DependsOn = '[WindowsFeature]DNS';
        }

        xDnsServerPrimaryZone 'DNS_Zone_0_107_131_InAddr_Arpa' {
            Name = '0.107.131.in-addr.arpa';
            ZoneFile = '0.107.131.in-addr.arpa.dns'
            DependsOn = '[WindowsFeature]DNS';
        }

        xDnsARecord 'DNS_A_edge1_contoso_com' {
            Zone = 'contoso.com';
            Name = 'edge1';
            Target = '131.107.0.2';
            DependsOn = '[xDnsServerPrimaryZone]DNS_Zone_contoso_com';
        }

        xDnsServerPrimaryZone 'DNS_Zone_isp_example_com' {
            Name = 'isp.example.com';
            ZoneFile = 'isp.example.com.dns'
            DependsOn = '[WindowsFeature]DNS';
        }

        xDnsARecord 'DNS_A_inet1_isp_example_com' {
            Zone = 'isp.example.com';
            Name = 'inet1';
            Target = '131.107.0.1';
            DependsOn = '[xDnsServerPrimaryZone]DNS_Zone_isp_example_com';
        }

        xDnsServerPrimaryZone 'DNS_Zone_msftncsi_com' {
            Name = 'msftncsi.com';
            ZoneFile = 'msftncsi.com.dns'
            DependsOn = '[WindowsFeature]DNS';
        }

        xDnsARecord 'DNS_A_www_msftncsi_com' {
            Zone = 'msftncsi.com';
            Name = 'www';
            Target = '131.107.0.1';
            DependsOn = '[xDnsServerPrimaryZone]DNS_Zone_msftncsi_com';
        }

        #xDnsARecord 'dns_msftncsi_com' {
        #    Zone = 'msftncsi.com';
        #    Name = 'dns';
        #    Target = '131.107.255.255.';
        #    DependsOn = '[xDnsServerPrimaryZone]DNS_Zone_msftncsi_com';
        #}

    } #end nodes INET
}
