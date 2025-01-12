

$TEXT_COLLECTOR_PATH="C:\Program Files\windows_exporter\textfile_inputs"


function GetHyperVVMState {
    # We'll exclude all machines which aren't set for automatic start, since we don't need to get VM state

    $prometheus_status = "# HELP windows_hyperv_vm_status '1' the vm not running
# TYPE windows_hyperv_vm_status gauge
# HELP windows_hyperv_vm_state '1' if the vm in a bad shape
# TYPE windows_hyperv_vm_state gauge`n"

    $vms = Get-VM | Where-Object {$_.AutomaticStartAction -eq 'Start'}

    foreach ($vm in $vms) {    
        if ($vm.State -eq "Running") {
            $running = 0
        } else {
        # Avoid alerting non running replicas
            if ((Get-VMReplication $vm).Mode -eq "Replica") {
                continue
            }
            $running = 1
        }

        # Get list of possible OperationalStatus with
        # [enum]::GetNames([Microsoft.HyperV.Powershell.VMOperationalStatus])
        # Use vm.OperationalStatus and never use vm.Status as advertised by Get-VM since it will return localized output
        # see https://stackoverflow.com/questions/79140459/hyper-v-get-vm-output-language?noredirect=1#comment139582523_79140459

    
        $good_states = ('Ok', 'InService', 'ApplyingSnapshot', 'CreatingSnapshot', 'DeletingSnapshot', 'MergingDisks', 'ExportingVirtualMachine', 'MigratingVirtualMachine', 'BackingUpVirtualMachine', 'ModifyingUpVirtualMachine', 'StorageMigrationPhaseOne', 'StorageMigrationPhaseTwo', 'MigratingPlannedVm')
        if ($good_states.contains([string]$vm.OperationalStatus)) {
            $healthy = 0
        } else {
            $healthy = 1
        }

        $vmname = $vm.Name
        $vmhost = (Get-VMHost).Name

        $prometheus_status += "windows_hyperv_vm_status{vm=`"" + $vmname + "`",host=`"" + $vmhost + "`"} $running`n"
        $prometheus_status += "windows_hyperv_vm_state{vm=`"" + $vmname + "`",host=`"" + $vmhost + "`"} $healthy`n"

    }
    return $prometheus_status
}

function GetHyperVReplicationState {
    $prometheus_status = "# HELP windows_hyperv_replication_health_status '1' if the replication in bad health
# TYPE windows_hyperv_replication_health_status gauge
# HELP windows_hyperv_replication_status '1' if replication is not ongoing
# TYPE windows_hyperv_replication_status gauge`n"

    $replications = Get-VMReplication

    foreach ($replication in $replications) {
        if ($replication.ReplicationHealth -eq "Normal") {
            $healthy = 0
        } else {
            $healthy = 1
        }

        if ([String]$replication.ReplicationState -eq "Replicating") {
            $replicating = 0
        } else {
            $replicating = 1
        }

        $vmname = $replication.VMName
        $source = $replication.PrimaryServerName
        $dest = $replication.ReplicaServerName

        $prometheus_status += "windows_hyperv_replication_health_status{vm=`"" + $vmname + "`",source=`"" + $source + "`",destination=`"" + $dest + "`"} $healthy`n"
        $prometheus_status += "windows_hyperv_replication_status{vm=`"" + $vmname + "`",source=`"" + $source + "`",destination=`"" + $dest + "`"} $replicating`n"

    }
    return $prometheus_status
}


$prometheus_status = ""
$prometheus_status += GetHyperVVMState
$prometheus_status += GetHyperVReplicationState

$prom_file = Join-Path -Path $TEXT_COLLECTOR_PATH -ChildPath "hyperv_health.prom"
# The following command forces powershell to create a UTF-8 file without BOM, see https://stackoverflow.com/a/34969243
$null = New-Item -Force $prom_file -Value $prometheus_status