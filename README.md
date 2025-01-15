# A Powershell Windows PrinterSetup-Script
Takes printer setup files from a directory, and installs printers onto other machines via PowerShell without using external remoting software.

The goal of this script was to take the time-consuming inconveniences of adding printers for users on the same network (whether physically or on a VPN) and allow someone who has the Driver Software of the printer to swiftly add it to other PCs.

In doing so, anyone can with Powershell 7 can run this script with most error handling checked for you, such as: wrong IPs for Computers/Printers, bad directories for finding requried files for installation, etc.

My inspiration to build upon an automated printer setup script came from a website that details the 4 major commands for printer setups: https://www.pdq.com/blog/using-powershell-to-install-printers/

# How to run the script:

  If within a powershell IDE, simply loading the script and running it should be enough. If in a terminal, the standard method of .ps1 execution is just fine via ```.\script.ps1```

  When running the script, you must have:
  - Directory for driver software with the .inf file in that ending folder path
  - A .csv file that fits the same criteria as the example .csv file in the repository for CANON printers (if adding CANON printers, that one driver should suit 90% of all CANON Printers as they all use the exact same driver).

  After pasting the directories to the script, the script will then parse all printer directories available, and list them out in a number format for you! Choose your number, and the installation begins!

## Mitigating Runtime of the Script
There are a few questions (Check each Read-Host command in the script) that can be hard-coded later for your convenience, as these prompts will slow the progress ESPECIALLY when adding multiple printers.

Also, you can add more printer directories to the .csv file to fit however many printers your location uses!

# Requirements:
    - PowerShell 7 Installation required (script was made as of this ReadMe with Powershell 7.4.5)
    - The Printer Driver Software of your choosing with a .inf file

# Troubleshooting Tips
  - The main issue forseen is going to be the .csv file. It takes a couple items into question.
    1. The Model of the printer AS LISTED in the .inf File of the printer. For example, in the CANON UFR II driver files, the .inf file lists the printer name as ```Canon Generic Plus UFR II``` when viewed in a text editor such as NotePad/Visual Studio Code, so that's what is listed in the .csv file. You must investigate to find the driver name. If the driver software comes as an installer such as a .exe file, I like to use 7-Zip to extract the contents of the exeecutable. From there you can remove any applications as are not needed to save space. I don't know what all is needed besides the .inf files and security catalog files, so if you want to trim it more you'd have to research or TRIAL AND ERROR!
    2. The .inf file name for the driver software. On Windows you can view the **properties** of a file to validate it being a .inf file. This file is what directs windows for installing the driver on your machine, as well as connecting the printer to it. 
