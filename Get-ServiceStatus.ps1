<#
    .SYNOPSIS
      Checks operational status of a service on domain controllers.
    
    .DESCRIPTION
      This script will query all domain controllers in the domain and audit the status of a service (installed, running, stopped, etc.).
      Progress is shown in the console during runtime along with results.
    
    .PARAMETER Domain
      The domain containing domain controllers to check service status on.

    .PARAMETER ServiceName
      The name of the servive to check.  Acceptable formats are "Name" and "DisplayName".
      For example, "AppMgmt" or "Application Management".
    
    .EXAMPLE
      Get-ServiceStatus -Domain "<domain.com>" -ServiceName "<service name>"
      The function is run to collect operational status of the service (installed, running, etc.).
    
    .INPUTS
      System.ServiceProcess.ServiceController, System.String
        
    .OUTPUTS
      System.ServiceProcess.ServiceController
    
    .NOTES
      NAME: Get-ServiceStatus.ps1
      AUTHOR: Edward Bernard, Directory Services Team
      CREATED: 1/8/2019
      LASTEDIT: 1/9/2019
      VERSION: 2.0.0 Added Try/Catch block; updated comment help section.
      VERSION: 1.0.0
    
    .LINK
      https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service?view=powershell-6
#>
function Get-ServiceStatus {

    param(
            [Parameter(Manadatory)]
            [string]$Domain,
            [Parameter(Manadatory)]
            [string]$ServiceName
        )
    
        Begin {
                    # $domain = "contoso.com"
                    # $serviceName = "CcmExec"
                    $DCs = (Get-ADDomainController -Server $Domain -Filter *).HostName
                    $pingCount = 0
                    $results = @()
            }
        Process {
                    Foreach ($DC in $DCs) {
                    $Ping = Test-Connection $DC -Count 2 -Quiet
                    $pingCount++
                    $progressParams = @{
                                       'Activity' = 'Checking connectivity'
                                        'Status'   = "Waiting for response from endpoint: {0} / {1} - {2:p}" -f $pingCount, $DCs.Count, ($pingCount / $DCs.count)
                                        'PercentComplete' = (($pingCount / $($DCs.count)) * 100) -as [int]
                                    }
                    Write-Progress @progressParams
    
                    If ($Ping -eq 'True') {
                        Try {
                            $serviceStatus = Get-Service -ComputerName $DC $ServiceName -ErrorAction Stop
                            $Hash = [ordered]@{
                                                "Computer"    = $DC
                                                "Online"      = "True"
                                                "Name"        = $serviceStatus.Name 
                                                "DisplayName" = $serviceStatus.DisplayName
                                                "Status"      = $serviceStatus.Status                          
                                            }
                            }
                        Catch {
                                $Hash = [ordered]@{
                                                    "Computer"    = $DC
                                                    "Online"      = "True"
                                                    "Name"        = "Service not found" 
                                                    "DisplayName" = "Service not found"
                                                    "Status"      = "Check system."
                                                }
                            }
                        } 
                    Else {
                            $Hash = [ordered]@{
                                                "Computer"    = $DC
                                                "Online"      = "False"
                                                "Name"        = $null 
                                                "DisplayName" = $null
                                                "Status"      = "Warning: Check system."
                                            }                           
                        } # End If else
                        $results += New-Object psobject -Property $Hash
                    } # End foreach 
                } # End process
        End {
                $results | Out-GridView -Title "Status Details for Service: $($ServiceName)"
            }
} # End function