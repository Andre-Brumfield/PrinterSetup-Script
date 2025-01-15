# A Powershell Windows PrinterSetup-Script
Takes printer setup files from a directory, and installs printers onto other machines via PowerShell without using external remoting software.

The goal of this script was to take the time-consuming inconveniences of adding printers for users on the same network (whether physically or on a VPN) and allow someone who has the Driver Software of the printer to swiftly add it to other PCs.

In doing so, anyone can with Powershell 7 can run this script with most error handling checked for you, such as: wrong IPs for Computers/Printers, bad directories for finding requried files for installation, etc.

My inspiration to build upon an automated printer setup script came from a website that details the 4 major commands for printer setups: https://www.pdq.com/blog/using-powershell-to-install-printers/

# How to run the script:

  If within a powershell IDE, simply loading the script and running it should be enough. If in a terminal, the standard method of .ps1 execution is just fine via ```.\script.ps1```

  When running the script, you must have:
  - Directory for driver software with the .inf file in that ending folder path
  - A .csv file that fits the same criteria as the example .csv file in the repository.

  After pasting the directories to the script,

## Mitigating Runtime of the Script
There are a few questions (Check each Read-Host command in the script) that can be hard-coded later for your convenience, as these prompts will slow the progress ESPECIALLY when adding multiple printers.

Also, you can add more printer directories to the .csv file to fit however many printers your location uses!

# Requirements:
    - PowerShell 7 Installation required (script was made as of this ReadMe with Powershell 7.4.5)
    - The Printer Driver Software of your choosing with a .inf file
