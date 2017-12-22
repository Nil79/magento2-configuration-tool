# Magento2 Configuration Tool
A tool of utilities to configure and upgrade Magento2 and its modules

## Usage
* Copy mageconfig.sh file inside root folder of Magento2
* Give correct permissions to file (chmod +x mageconfig.sh)
* Execute the bash file sh mageconfig.sh

## Configure the sh file

Inside the file you have to set the proper value for these three variables:
* comp_option: custom options used during compile and static deployment (ex: -dmemory_limit=5G). Leave empty if not needed.
* user: the current user of vhost
* group: the grupp for the current user of vhost

## What's New

The current version provides these features:
* Managing cache
* Reindexing
* Modules Upgrade
* Reset File Permissions
* Compile
* Static deployment
* Upgrading Magento (To desired version)
* Enabling/Disabling modules and checking modules status
