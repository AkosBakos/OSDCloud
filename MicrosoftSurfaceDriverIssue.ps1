#=======================================================================
#  [PostOS] Driver Management for Microsoft Surface devices
#=======================================================================
$Get_Manufacturer_Info = (Get-WmiObject Win32_ComputerSystem).Manufacturer
if ($Get_Manufacturer_Info -like "Microsoft") {
    Write-Host -ForegroundColor Cyan "Device manufacturer is Microsoft Corporation --> need to download some drivers"
    $Get_Product_Info = (Get-MyComputerProduct)

    Write-Host -ForegroundColor Gray "Getting OSDCloudDriverPackage for this $Get_Product_Info"
    $DriverPack = Get-OSDCloudDriverPacks | Where-Object { ($_.Product -contains $Get_Product_Info) -and ($_.OS -match $Params.OSVersion) }

    if ($DriverPack) {
        [System.String]$DownloadPath = 'C:\Drivers'
        if (-NOT (Test-Path "$DownloadPath")) {
            New-Item $DownloadPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $OutFile = Join-Path -Path $DownloadPath -ChildPath ($DriverPack.FileName -join "")


        Write-Host -ForegroundColor Cyan "ReleaseDate: $($DriverPack.ReleaseDate)"
        Write-Host -ForegroundColor Cyan "Name: $($DriverPack.Name)"
        Write-Host -ForegroundColor Cyan "Product: $($DriverPack.Product)"
        Write-Host -ForegroundColor Cyan "Url: $($DriverPack.Url)"
        if ($DriverPack.HashMD5) {
            Write-Host -ForegroundColor Cyan "HashMD5: $($DriverPack.HashMD5)"
        }
        Write-Host -ForegroundColor Cyan "OutFile: $OutFile"

        # Check if $DriverPack is an array
        if ($DriverPack -is [System.Collections.IEnumerable]) {
            foreach ($pack in $DriverPack) {
                # Check if the object has the Url property
                if ($pack.PSObject.Properties['Url']) {
                    $url = [string]$pack.Url
                    Write-Host "DriverPack.Url: $url"

                    # Check for null or empty values
                    if ([string]::IsNullOrEmpty($url)) {
                        Write-Host "DriverPack.Url is null or empty"
                    }
                    else {
                        Save-WebFile -SourceUrl $url -DestinationDirectory $DownloadPath -DestinationName $pack.FileName
                    }
                }
                else {
                    Write-Host "The property 'Url' cannot be found on this object."
                }
            }
        }
        else {
            Write-Host "DriverPack is not an array."
        }

        if (! (Test-Path $OutFile)) {
            Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Driver Pack failed to download"
        }

        $DriverPack | ConvertTo-Json | Out-File "$OutFile.json" -Encoding ascii -Width 2000 -Force
    }
}
