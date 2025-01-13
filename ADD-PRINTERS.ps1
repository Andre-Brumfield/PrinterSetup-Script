# Description: Installs the stored drivers of printers onto remote computers instead of manual printer setup tools.
# Supports one, or many printers being added at a time, and keeps track of which printers succeeded, and which failed.
# Author: Andre Brumfield
# Version: 1.2

# Info: This script can be ONLY be ran REMOTELY, does not work running the script from the host machine.

# The username variables takes the whoami function in powershell to get the user currently signed into the machine's username for driver storage.
$username = (whoami).split("\")[1]
$ipv4Pattern = '^(\d{1,3}\.){3}\d{1,3}$'
$counter = 0
#---------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host "Printer Setup Utility"
# Add_Printers? Function gets the initial information for the printer/computer in question, to discern if they are available before going any further.
# It will then create a PSSession to the machine to allow remote commands.
Function Printer_Setup{
    $prompt = Read-Host "Printer Installation - (O)ne computer or M(ultiple) computers that we're adding the Printer to"
    $global:printerip = Read-Host "Printer's Host Name"

    # The if statement below ensures a printer is added via Host Name, as when on an enterprise network with static Host Names but changing IPs, it ensures consistency over time.
    # The if statement can be removed to allow IP addresses if need be.
    if ($printerip -match $ipv4Pattern) {
        Write-Host "Error: An IP address was entered. Please enter a hostname next time. `n"
        Printer_Setup
    }
    if (Test-Connection -ComputerName $printerip -Count 1 -ErrorAction SilentlyContinue) {
        if ($prompt -eq "O" -or $userInput -eq "o") {
            $global:computer = Read-Host "PC Name for Printer to be added to"
            Write-Host "Checking for PC Connection...."
            if (Test-Connection -ComputerName $computer -Count 1 -ErrorAction SilentlyContinue) {
                $global:session = New-PSSession -ComputerName $computer #-Credential $runner
                Model
            }
            else{
                Write-Host "The PC Name "$computer" could not be pinged, verify spelling and that the PC is on the network!"
            }
        }
        elseif ($prompt -eq "M" -or $userInput -eq "m"){
            Write-Host "There must be a .txt file that contains all the computers that need the printer added on each line, such as:"
            Start-Sleep -Seconds 0.5
            Write-Host "UTHSC1234"
            Start-Sleep -Seconds 0.5
            Write-Host "UTHSC2345"
            Start-Sleep -Seconds 0.5
            Write-Host "UTHSC3456"
            Start-Sleep -Seconds 1

            $prompt = Read-Host "Please paste the directory where the .txt file is located, no quotations please. Feel free to hard code the directory to just reference the .txt file in the future!"
            if (-not (Test-Path -Path $prompt)){
                Write-Host "Faulty Path to your .txt file, try again!"
                Add_Printers?
            }

            $computers = Get-Content -Path $prompt
            $bad = @()
            $good = @()
            foreach ($global:computer in $computers){
                Write-Host "Checking for PC Connection...."
                if (Test-Connection -ComputerName $computer -Count 1 -ErrorAction SilentlyContinue) {
                    $good += ($computer)
                    $global:session = New-PSSession -ComputerName $computer #-Credential $runner
                    Write-Host "Attempting installation on $computer..."
                    if ($counter -lt 1){
                        Model
                        $counter++
                    }
                    else{
                        Driver_Install $hpPrinterInf $model
                    }
                }
                else{
                    $bad = $bad + ($computer)
                }
            }
            Write-Host "Script ran for PC List: $good, but these were unavailable; please notate for your records: $bad"
        }
        else{
            Write-Host "Your input"$prompt" does not match the options above (letters O, o, M, or m), exiting program."
        }
    }
    else{
        Write-Host "The Host Name "$printerip" could not be pinged, verify spelling and that the printer is on the network!"
    }
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# The $printers variable reads a .csv file, then uses the Model Function to discern which Model to choose from for installation. Read the ReadMe file for further instruction/examples
$printers = Read-Host "Paste the path to your .csv file please, no quotations, you can hard-code this for future reference"
Import-Csv -Path "$printers"
Function Model {
    $counter = 1
    # Loop through each row and perform actions
    Write-Host "Models"
    Write-Host "------"
    $printers | ForEach-Object {
        Write-Host "$counter. $($_.Model)"
        $counter++
    }

    $rowNumber = Read-Host "Which Model Printer are you looking for? Choose the number that applies, or q to quit"

    if ($rowNumber -match '^\d+$') {
        $printer = $printers[$rowNumber - 1]
        if($printer -eq $null){
            Write-Host "You chose an empty value, please try again from the list above..."
            Model
        }
        $model = $printer.Model
        $hpPrinterInf = $printer.INF
        Write-Host "Checking for Driver Installation..."
        Driver_Install $hpPrinterInf $model
    }
    elseif ($rowNumber -eq "q" -or $rowNumber -eq "quit"){
        Write-Host "Ending Process..."
    }
    else{
        Write-Host "That is not a number, please try again..."
        Model
    }
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# The Driver_Install Function fulfills one of the two main powershell commands (Pnputil /add-driver) for adding the driver to the FileRepository folder on your Windows Machine.
# Additional code in the function are conditional checks to ensure the script runs as quickly as possible.
Function Driver_Install {
    param($hpPrinterInf, $model)

    $driverExists = Invoke-Command -Session $session -ScriptBlock {
        param($model)
        $InsDrivers = Get-PrinterDriver
        # Check if any installed driver matches the model
        return $InsDrivers.Name -contains $model
    } -ArgumentList $model

    if (-not $driverExists) {
        if (-not (Test-Path -Path "C:\Users\$username\PrinterDrivers")) {
            New-Item -Name "PrinterDrivers" -ItemType Directory -Path "C:\Users\$username\"
        }
        if (-not (Test-Path -Path "C:\Users\$username\PrinterDrivers\$model.zip")) {
            Write-Host "Driver will be installed on your computer in: C:\Users\$username\PrinterDrivers, before it is sent to the user. This should only happen the first time this model is added to prevent Double Hop Authentication measures."
            Copy-Item -Path "\\volshare\tssserver\PrintDrivers\$model.zip" -Destination "C:\Users\$username\PrinterDrivers"
        }

        Invoke-Command -Session $session -ScriptBlock {
            param($username)
            New-Item -Name "PrinterDrivers" -ItemType Directory -Path "C:\Users\$username\"
        } -ArgumentList $username


        # Driver not found, proceed with installation
        Copy-Item -Path "C:\Users\$username\PrinterDrivers\$model.zip" -Destination "C:\Users\$username\PrinterDrivers" -Force -ToSession $session
        Invoke-Command -Session $session -ScriptBlock {
            param($username, $model, $hpPrinterInf)
            Expand-Archive -Path "C:\Users\$username\PrinterDrivers\$model.zip" -DestinationPath "C:\Users\$username\PrinterDrivers"
            Pnputil /add-driver "C:\Users\$username\PrinterDrivers\$model\$hpPrinterInf.INF"
            #Write-Host "C:\Users\$username\PrinterDrivers\$model\$hpPrinterInf.INF"
            Remove-Item -Path "C:\Users\$username\PrinterDrivers" -Recurse -Force
        } -ArgumentList $username, $model, $hpPrinterInf 

        Write-Host "Successfully installed driver, tidying installation..."
        $hpPrinterInf = $hpPrinterInf
        $model = $model
        Add_Printer_Driver $hpPrinterInf $model
    }
    else {
        Write-Host "Printer driver already installed, skipping installation. Checking Ports..."
        Add_Printer_Port $model
    }
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# The Add_Printer_Driver Function fulfills the second of the two main powershell commands (Add-PrinterDriver) now that it has an installed driver, alongside a .inf file to reference in the FIle Repository
Function Add_Printer_Driver {
    param ($hpPrinterInf, $model)

    Write-Host "Setting up Driver for Printer Installation...."
    Invoke-Command -Session $session -ScriptBlock {
        param($hpPrinterInf, $model)
        #$hpPrinterInf
        #$model

        $rootPath = "C:\Windows\System32\DriverStore\FileRepository\"
        $fileNameStart = $hpPrinterInf
        #The $driver variable grabs the printer name that matches the value (model) referenced in the $fileNameStart variable
        $driver = Get-ChildItem -Path $rootPath | Where-Object { $_.Name -like "$fileNameStart*" } | Select-Object -First 1
        $midPath = "$rootPath$driver\"
        Write-Host "Almost there, Path: $midPath"
        $driver = $hpPrinterInf
        $driver = Get-ChildItem -Path $midPath -Filter "*.inf"
        $insPath = "$midPath$driver"
        Write-Output "Installation path: $insPath"
        
        Add-PrinterDriver -Name $model -InfPath $insPath
    } -ArgumentList $hpPrinterInf, $model
    
    Write-Host "Printer driver is now setup... checking port..."
    $model = $model
    Add_Printer_Port $model
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Add_Printer_Port initializes the port (or can find the port that was already created for the same printer) to connect to the Driver.
Function Add_Printer_Port{
    param ($model)
    $portExists = Invoke-Command -Session $session -ScriptBlock {
        param($printerip)
        $InsPorts = Get-PrinterPort
        # Check if any installed port matches the Printer's Host Name
        return $InsPorts.Name -contains $printerip
    } -ArgumentList $printerip


    if (-not $portExists) {
        Invoke-Command -Session $session -ScriptBlock {
            Add-PrinterPort -Name $printerip -PrinterHostAddress $printerip
        }
        Write-Host "Port successfully added, finalizing printer installation"
        AddPrinter $model
    }
    else{
        Write-Host "Port already configured, finalizing printer installation"
        AddPrinter $model
    }
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Final AddPrinter Function fully adds the printer in "Printers/Scanners"
Function AddPrinter{
    param ($model)

    Invoke-Command -Session $session -ScriptBlock {
        param($model, $printerip)
        try {
            # Attempt to add the printer
            $name = Read-Host "Printer Name? The Host Name will already be appended"
            Add-Printer -DriverName $model -Name "$name($printerip)" -PortName $printerip
            Write-Host "Printer '$name($printerip)' added successfully."
        }
        catch {
            #Catch the error for printer already existing.
            if ($_.Exception.Message -like "*already exists*") {
                Write-Host "This Printer is already in Printers/Scanners. Please remove and try again for fresh installation if needed."
            } 
            else {
                # Handle other exceptions
                Write-Host "An unexpected error occurred: $($_.Exception.Message)"
            }
        }
    } -ArgumentList $model, $printerip
    #Disconnects connection to that PC. Closing the ISE/Terminal disconnects sessions as well!
    Remove-PSSession -ComputerName $computer
    Read-Host "Press Enter to complete program..."
}

Printer_Setup