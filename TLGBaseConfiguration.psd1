@{
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            DefaultGateway              = '10.0.0.254';
            SubnetMask                  = 24;
            AddressFamily               = 'IPv4';
            DnsServerAddress            = '10.0.0.1';
            DomainName                  = 'corp.contoso.com';
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser        = $true;
        },
        @{
            NodeName                    = 'DC1';
            Role                        = 'DC';
            IPAddress                   = '10.0.0.1';
            DnsServerAddress            = '127.0.0.1';
        },
        @{
            NodeName                    = 'EDGE1';
            Role                        = 'EDGE';
            IPAddress                   = '10.0.0.2';
            IPAddress2                  = '131.107.0.2';
            InterfaceAlias2             = 'Ethernet 2';
            DefaultGateway2             = '131.107.0.254';
            SubnetMask2                 = 24;
            AddressFamily2              = 'IPv4';
            DnsServerAddress2           = '131.107.0.1';
        },
        @{
            NodeName                    = 'APP1';
            Role                        = 'APP';
            IPAddress                   = '10.0.0.3';
        },
        @{
            NodeName                    = 'INET1';
            Role                        = 'INET';
            IPAddress                   = '131.107.0.1';
            DnsServerAddress            = '127.0.0.1';
            DefaultGateway              = '131.107.0.254';
        },
        @{
            NodeName                    = 'CLIENT1';
            Role                        = 'CLIENT';
            IPAddress                   = '10.0.0.99';
        }
    );
    NonNodeData = @{

    };
};
