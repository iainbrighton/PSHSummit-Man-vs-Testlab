@{
    AllNodes = @(
        @{
            NodeName                        = '*';
            InterfaceAlias                  = 'Ethernet';
            DefaultGateway                  = '10.0.0.254';
            SubnetMask                      = 24;
            AddressFamily                   = 'IPv4';
            DnsServerAddress                = '10.0.0.1';
            DomainName                      = 'corp.contoso.com';
            CertificateFile                 = "$env:AllUsersProfile\VirtualEngineLab\Certificates\LabClient.cer";
            Thumbprint                      = '599E0BDA95ADED538154DC9FA6DE94920424BCB1';
            PSDscAllowDomainUser            = $true;
            VirtualEngineLab_SwitchName     = 'Corpnet';
            VirtualEngineLab_ProcessorCount = 1;
        },
        @{
            NodeName         = 'DC1';
            Role             = 'DC';
            IPAddress        = '10.0.0.1';
            DnsServerAddress = '127.0.0.1';
            VirtualEngineLab_ProcessorCount = 2;
        },
        @{
            NodeName         = 'EDGE1';
            Role             = 'EDGE';
            IPAddress        = '10.0.0.2';
            IPAddress2       = '131.107.0.2';
            InterfaceAlias2  = 'Ethernet 2';
            DefaultGateway2  = '131.107.0.254';
            SubnetMask2      = 24;
            AddressFamily2   = 'IPv4';
            DnsServerAddress2 = '131.107.0.1';
            VirtualEngineLab_WarningMessage = 'You must manually add a second network adapter!';
        },
        @{
            NodeName  = 'APP1';
            Role      = 'APP';
            IPAddress = '10.0.0.3';
        },
        @{
            NodeName                    = 'INET1';
            Role                        = 'INET';
            IPAddress                   = '131.107.0.1';
            DnsServerAddress            = '127.0.0.1';
            DefaultGateway              = '131.107.0.254';
            VirtualEngineLab_SwitchName = 'Internet';
            VirtualEngineLab_Media      = '2012R2_x64_Datacenter_EN_Eval';
        },
        @{
            NodeName               = 'CLIENT1';
            Role                   = 'CLIENT';
            IPAddress              = '10.0.0.99';
            VirtualEngineLab_Media = 'Win81_x64_Enterprise_EN_Eval';
            VirtualEngineLab_CustomBootStrap = @'
                net user Administrator /active:yes;  ## Enable the local Administrator
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force;
                Enable-PSRemoting -SkipNetworkProfileCheck -Force;  ## Kick start Win81 clients..
'@
        }
    );
    NonNodeData = @{
        VirtualEngineLab = @{
            Media = @();
            Network = @(
                @{ Name = 'Corpnet'; Type = 'Internal'; }
                @{ Name = 'Internet'; Type = 'Internal'; }
                # @{ Name = 'Corpnet'; Type = 'External'; NetAdapterName = 'Ethernet'; AllowManagementOS = $true; }
            );
        };
    };
};
