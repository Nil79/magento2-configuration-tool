#!/bin/bash
###### Functions ######
advanced(){
    admenu=true
    echo "Advanced Options"
    echo ""
    while "$admenu"
    do
        echo "Select an option:"
        adoptions=("Cache Enable" "Cache Disable"
        "Upgrade Magento" "Modules Status" "Module Enable" "Module Disable"
         "Back")
        select opt in "${adoptions[@]}"
        do
            case $opt in
                "Cache Enable")
                    switchCache true
                    break
                    ;;
                "Cache Disable")
                    switchCache false
                    break
                    ;;	
                "Upgrade Magento")
                    upgradeMagento
                    break
                    ;;
                "Modules Status")
                    moduleStatus
                    break
                    ;;
                "Module Enable")
                    moduleEnable
                    break
                    ;;
                "Module Disable")
                    moduleDisable
                    break
                    ;;
                "Back")
                    admenu=false
                    break
                    ;;
                *) echo "Invalid Option";;
            esac
        done
        echo ""
    done
}

moduleStatus() {
    printf "${GREEN}Checking modules status...\n"
    printf "${NC}"
    php bin/magento module:status
}

moduleEnable() {
    printf "${GREEN}Enabling module...\n"
    printf "${NC}"
    read -p "Type the module to enable:" name
    php bin/magento module:enable $name
}

moduleDisable() {
    printf "${GREEN}Disabling module...\n"
    printf "${NC}"
    read -p "Type the module to disable:" name
    php bin/magento module:disable $name
}

upgradeMagento() {
    printf "${RED}warning: Execute carefully this operation. Are you sure to continue? [Yn]\n"
    printf "${NC}"
    read -p "Yes or No? (Y, n)" value
    if [ $value == "Y" ]
    then
        executeUpgrade
    else
        if [ $value == "n" ] 
        then
            break
        else
            echo "Not valid choice"
            break
        fi
    fi
}

executeUpgrade() {
    printf "${GREEN}Upgrading Magento, the operation will take time. Relax and take a coffee break.\n"
    printf "${NC}"
    echo ""
    read -p "Type the version you want to upgrade to (eg.: 2.2.3):" version
    m2version="$(php bin/magento --version)"
    m2shortv=${m2version#*version}
    # compare version with m2shortv
    testvercomp $version $m2shortv '>'
}

startUpgrade() {
    echo "Upgrading to version $1"
    php composer.phar require magento/product-community-edition $1 --no-update
    php composer.phar update
    printf "${GREEN}Removing di and generation content...\n"
    printf "${NC}"
    #post upgrade operations
    rm -rf var/di var/generation 
    clean
    flush
    upgrade
    compile
    reindex
    deploy
    printf "${GREEN}Setting files permissions...\n"
    find . -type f -exec chmod 644 {} \;
    printf "Setting directories permissions...\n"
    find . -type d -exec chmod 755 {} \;
    printf "Setting var directory permissions...\n"
    find ./var -type d -exec chmod 777 {} \;
    printf "Setting pub/media directory permissions...\n"
    find ./pub/media -type d -exec chmod 777 {} \; 
    printf "Setting pub/static directory permissions...\n"
    find ./pub/static -type d -exec chmod 777 {} \; 
    printf "Setting app/etc directory permissions...\n"
    chmod 777 ./app/etc 
    printf "Setting app/etc xml files permissions...\n"
    chmod 644 ./app/etc/*.xml
    printf "Setting index.php permissions...\n"
    chmod 644 index.php
    printf "Setting bin/magento permissions...\n"
    chmod u+x bin/magento
    reset
    echo ""
    echo "The system upgrade has been performed..."
}

testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        echo "FAIL: The version number provided is wrong!"
        break
    else
        echo "Start Upgrading..."
        echo ""
        startUpgrade $1
    fi
}

# credits: https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

switchCache() {
    val="disable"
    if [ $1 == true ]
    then   
        val="enable"
    fi
    php bin/magento cache:$val
}

reset() {
    printf "${GREEN}Resetting file permissions..."
    printf "${NC}"
    chown -R $user:$group .
}

compile() {
    printf "${GREEN}Executing compile..."
    printf "${NC}"
    php "$comp_option" bin/magento setup:di:compile
}

deploy() {
    printf "${GREEN}Executing static content deployment..."
    printf "${NC}"
    read -p "Deploy for language package [leave empty for default package] (en_US,it_IT,de_De, etc.):" pack
    php "$comp_option" bin/magento setup:static-content:deploy $pack -f
}

upgrade() {
    printf "${GREEN}Upgrading modules..."
    printf "${NC}"
    php bin/magento setup:upgrade
}

clean() {
    printf "${GREEN}Cleaning cache..."
    printf "${NC}"
    php bin/magento cache:clean
}

flush() {
    printf "${GREEN}Flushing cache storage..."
    printf "${NC}"
    php bin/magento cache:flush
}

reindex() {
    printf "${GREEN}Reindexing..."
    printf "${NC}"
    php bin/magento indexer:reindex
}

##### Main #####
RED='\033[0;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

clear
echo "Welcome to Magento 2 Configuration Tool"
printf "${GREEN}date: 22th Dec 2017\n"
printf "${GREEN}author: sodano.n@gmail.com\n"
printf "${GREEN}version: 1.0.0-alpha\n"
printf "${GREEN}compatibility: Magento 2.2.x\n"
printf "${RED}warning: some options may not work on previous versions of Magento2\n"
printf "${NC}"
echo ""

menu=true
# CUSTOM VARIABLES TO CONFIGURE
comp_option="-dmemory_limit=5G" #leave empty is not needed
user="luxury"
group="luxury"

while "$menu"
do
    echo "Select an option:"
    options=("Clean Cache" "Flush Cache" "Compile" 
    "Reindex" "Reset Permissions" 
    "Deploy Static Content"
    "Setup Upgrade"
    "Advanced" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Clean Cache")
                clean
                break
                ;;	
            "Flush Cache")
                flush
                break
                ;;
            "Reindex")
                reindex
                break
                ;;
            "Compile")
                compile
                reset
                break
                ;;
            "Deploy Static Content")
                deploy
                reset
                break
                ;;
            "Reset Permissions")
                reset
                break
                ;;
            "Setup Upgrade")
                upgrade
                echo "" 
                compile
                reset
                break
                ;;
            "Advanced")
                advanced
                break
                ;;
            "Quit")
                echo "Bye"
                menu=false
                break
                ;;
            *) echo "Invalid Option";;
        esac
    done
    echo ""
done

