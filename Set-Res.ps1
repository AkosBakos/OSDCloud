function fCalculateVMVideoRAM([Int32]$iScreenWidth,[Int32]$iHeight){
    [Int64]$iVideoRAM=$iScreenWidth*$iHeight*4
    if(($iVideoRAM % 65536) -ne 0){
        $iVideoRAM=([System.Math]::Truncate($iVideoRAM/65536)+1)*65536
    }
    if($iVideoRAM -le 16777216){Write-Host -ForegroundColor Green "This resolution is already support by VMware Workstation" }
    if($iVideoRAM -le 4194304){Write-Host -ForegroundColor Green "This resolution is already support by VMware ESXi" }
    if($iVideoRAM -gt (128*1024*1024)){Write-Host -ForegroundColor  Red "This exceeds Max Video RAM on VMware ESXi 5.0" }
    if($iVideoRAM -gt (128*1024*1024)){Write-Host -ForegroundColor  Red "This exceeds Max Video RAM on VMware Workstation 9" }
    if($iVideoRAM -gt (512*1024*1024)){Write-Host -ForegroundColor  Red "This exceeds Max Video RAM on VMware ESXi 5.1 and 5.5" }
    if($iVideoRAM -gt (512*1024*1024)){Write-Host -ForegroundColor  Red "This exceeds Max Video RAM on VMware Workstation 10" }
    Write-Host "Parameters"
    Write-Host "svga.maxWidth =" $iScreenWidth.ToString()
    write-host "svga.maxHeight =" $iHeight.ToString()
    write-host "svga.vramSize =" $iVideoRAM.ToString()
}
