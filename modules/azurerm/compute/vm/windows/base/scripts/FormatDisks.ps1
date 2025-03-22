# Define Vars
$tmp_dir = "$env:SystemDrive\Windows\temp"

# Logging Function
Function Write-Log($message, $level = "INFO") {
    $date_stamp = Get-Date -Format s
    $log_entry = "$date_stamp - $level - $message"
    if (-not (Test-Path -Path $tmp_dir)) {
        New-Item -Path $tmp_dir -ItemType Directory > $null
    }
    $log_file = "$tmp_dir\FormatDisks.log"
    Write-Host $log_entry
    Add-Content -Path $log_file -Value $log_entry
}

# Process New Disks
$disks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }

if ($disks) {
    foreach ($disk in $disks) {
        Write-Log "Initializing disk: $($disk.Number)"
        
        # Use GPT if disk > 2TB, otherwise use MBR
        if ($disk.Size -gt 2TB) {
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT -PassThru | Out-Null
            Write-Log "Disk $($disk.Number) initialized as GPT"
        } else {
            Initialize-Disk -Number $disk.Number -PartitionStyle MBR -PassThru | Out-Null
            Write-Log "Disk $($disk.Number) initialized as MBR"
        }
        
        # Create a new partition
        $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
        Write-Log "Partition created on disk $($disk.Number), assigned drive letter $($partition.DriveLetter)"

        # Format the partition as NTFS
        Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false
        Write-Log "Formatted drive $($partition.DriveLetter) as NTFS"
    }
} else {
    Write-Log "No raw disks found, skipping initialization."
}

Write-Log "Disk formatting complete."