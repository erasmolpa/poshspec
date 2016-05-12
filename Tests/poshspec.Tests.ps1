$ModuleManifestName = 'poshspec.psd1'
Import-Module $PSScriptRoot\..\$ModuleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\$ModuleManifestName
        $? | Should Be $true
    }
}

Describe 'Get-PoshspecParam' {
    InModuleScope PoshSpec {
        Context 'One Parameter' {
            $results = Get-PoshspecParam -TestName MyTest -TestExpression {Get-Item $Target} -Target Name -Should { Should Exist }

            It "Should return the correct test Name" {
                $results.Name | Should Be "MyTest 'Name' Should Exist"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-Item 'name' | Should Exist"
            }            
        }
        
        Context 'Two Parameters' {
            $results = Get-PoshspecParam -TestName MyTest -TestExpression {Get-Item $Target $Property} -Target Name -Property Something -Should { Should Exist }

            It "Should return the correct test Name" {
                $results.Name | Should Be "MyTest property 'Something' for 'Name' Should Exist"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-Item 'name' 'Something' | Select-Object -ExpandProperty 'Something' | Should Exist"
            }                
        }
        
        Context 'Three Parameters' {
            $results = Get-PoshspecParam -TestName MyTest -TestExpression {Get-Item $Target $Property $Qualifier} -Target Name -Property Something -Qualifier 1 -Should { Should Exist }

            It "Should return the correct test Name" {
                $results.Name | Should Be "MyTest property 'Something' for 'Name' at '1' Should Exist"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-Item 'name' 'Something' '1' | Select-Object -ExpandProperty 'Something' | Should Exist"
            }            
        }        
        
        Context 'Expression handling' {
            
            It "Should thow and error if missing a property" {
                { Get-PoshspecParam -TestName MyTest -TestExpression {Get-Item $Target $Property} -Target Name -Should { Should Exist } } | Should Throw
            }
        }
    }    
}

Describe 'Test Functions' {
    InModuleScope PoshSpec {
        Mock Invoke-PoshspecExpression {return $InputObject}
        
        Context 'Service' {
         
            $results = Service w32time Status { Should Be Running }

            It "Should return the correct test Name" {
                $results.Name | Should Be "Service property 'Status' for 'w32time' Should Be Running"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-Service -Name 'w32time' | Select-Object -ExpandProperty 'Status' | Should Be Running"
            }
        }
        
        Context 'File' {

            $results = File C:\inetpub\wwwroot\iisstart.htm { Should Exist }

            It "Should return the correct test Name" {
                $results.Name | Should Be "File 'iisstart.htm' Should Exist"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "'C:\inetpub\wwwroot\iisstart.htm' | Should Exist"
            }
        }
        
        Context 'Registry w/o Properties' {

            $results = Registry HKLM:\SOFTWARE\Microsoft\Rpc\ClientProtocols { Should Exist }
            
            It "Should return the correct test Name" {
                $results.Name | Should Be "Registry 'ClientProtocols' Should Exist"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "'HKLM:\SOFTWARE\Microsoft\Rpc\ClientProtocols' | Should Exist"
            }
        }
        
        Context 'Registry with Properties' {
            
            $results = Registry HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\ "NV Domain" { Should Be mybiz.local  }        
            
            It "Should return the correct test Name" {
                $results.Name | Should Be "Registry property 'NV Domain' for 'Parameters' Should Be mybiz.local"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\' | Select-Object -ExpandProperty 'NV Domain' | Should Be mybiz.local"
            }            
        }
        
        Context 'HTTP' {
            
            $results = Http http://localhost StatusCode { Should Be 200 }
            
            It "Should return the correct test Name" {
                $results.Name | Should Be "Http property 'StatusCode' for 'http://localhost' Should Be 200"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Invoke-WebRequest -Uri 'http://localhost' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'StatusCode' | Should Be 200"
            }            
        }
        
        Context 'TcpPort' {

            $results = TcpPort localhost 80 PingSucceeded { Should Be $true }
            
            It "Should return the correct test Name" {
                $results.Name | Should Be "TcpPort property 'PingSucceeded' for 'localhost' at '80' Should Be `$true"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Test-NetConnection -ComputerName 'localhost' -Port '80' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'PingSucceeded' | Should Be `$true"
            }            
        } 
        
        Context 'Hotfix' {
         
            $results = Hotfix KB1234567 { Should Exist }
            
            It "Should return the correct test Name" {
                $results.Name | Should Be "Hotfix 'KB1234567' Should Exist"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-HotFix -Id 'KB1234567' -ErrorAction SilentlyContinue | Should Exist"
            }
        }
        
        Context 'CimObject w/o Namespace' {
         
            $results = CimObject Win32_OperatingSystem SystemDirectory { Should Be C:\WINDOWS\system32 }

            It "Should return the correct test Name" {
                $results.Name | Should Be "CimObject property 'SystemDirectory' for 'Win32_OperatingSystem' Should Be C:\WINDOWS\system32"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-CimInstance -ClassName 'Win32_OperatingSystem' | Select-Object -ExpandProperty 'SystemDirectory' | Should Be C:\WINDOWS\system32"
            }
        }        
        Context 'CimObject with Namespace' {
         
            $results = CimObject root/Microsoft/Windows/DesiredStateConfiguration/MSFT_DSCConfigurationStatus Error { Should BeNullOrEmpty }

            It "Should return the correct test Name" {
                $results.Name | Should Be "CimObject property 'Error' for 'MSFT_DSCConfigurationStatus' at 'root/Microsoft/Windows/DesiredStateConfiguration' Should BeNullOrEmpty"
            }

            It "Should return the correct test Expression" {
                $results.Expression | Should Be "Get-CimInstance -ClassName 'MSFT_DSCConfigurationStatus' -Namespace 'root/Microsoft/Windows/DesiredStateConfiguration' | Select-Object -ExpandProperty 'Error' | Should BeNullOrEmpty"
            }
        }   
    }
}

Remove-Module Poshspec