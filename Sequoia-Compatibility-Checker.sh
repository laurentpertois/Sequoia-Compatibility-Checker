#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2024 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# This script is published here:
# https://github.com/laurentpertois/Sequoia-Compatibility-Checker
#
# Other scripts and resources available here:
# https://github.com/laurentpertois?tab=repositories
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This script was designed to be used as an Extension Attribute to ensure specific
# requirements have been met to deploy macOS Sequoia.
#
# General Requirements:
#		- OS X 10.9.0 or later (It seems, as of the day I write this Apple has not yet made recommendations, this page and the script will be adapted if necessary when the information will become public)
#		- 4GB of memory (It seems, as of the day I write this Apple has not yet made recommendations, this page and the script will be adapted if necessary when the information will become public)
#		- 20GB of available storage (It seems, as of the day I write this Apple has not yet made recommendations, this page and the script will be adapted if necessary when the information will become public)
#
#
# These last 2 requirements can be modified in the first 2 variables (MINIMUMRAM
# and MINIMUMSPACE).
# 	- REQUIREDMINIMUMRAM: minimum RAM required, in GB
# 	- REQUIREDMINIMUMSPACE: minimum disk space available, in GB. Sequoia has different
#							requirements depending on the OS from which you update
#							Adjust to your needs, lines 79 (Catalina) or 82 (pre-Catalina) 
#
#
# Mac Hardware Requirements and equivalent as minimum Model Identifier
#  	- MacBook Pro (2018 or newer), ie MacBookPro15,1
#  	- MacBook Air (2020 or newer), ie MacBookAir9,1
#  	- Mac mini (2018 or newer), ie Macmini8,1
#  	- iMac (2019 or newer), ie iMac19,1
#  	- iMac Pro, ie iMacPro1,1
#  	- Mac Pro (2019), ie MacPro7,1
#  	- Mac Studio (2022), ie Mac13,1 Mac13,2
#	- MacBook Air M2 (2022), ie Mac14,15 Mac14,2
#	- MacBook Pro M2 (2022), ie Mac14,5 Mac14,6 Mac14,7 Mac14,9 Mac14,10
#	- Mac Pro (2023), ie Mac14,8
#  	- Mac Studio (2023), ie Mac14,13 Mac14,14
#	- MacBook Pro M3 (2023), ie Mac15,3 Mac15,6 Mac15,7 Mac15,8 Mac15,9 Mac15,10 Mac15,11
#	- iMac (2023), ie Mac15,4 Mac15,5
#	- MacBook Air M3 (2024), ie Mac15,12 Mac15,13
#
#
# Default compatibility is set to False if no test pass (variable COMPATIBILITY)
#
# Written by: Laurent Pertois | Senior Professional Services Engineer | Jamf
#
# Created On: 2024-06-10
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Checks minimum version of the OS before upgrade (10.9.0)
OSVERSIONMAJOR=$(sw_vers -buildVersion | cut -c 1-2)

# Minimum RAM and Disk Space required (4GB and 45GB default. Note that REQUIREDMINIMUMSPACE must be set to an integer)
# According to https://support.apple.com/en-us/HT211238 the minimum space requirement for Sequoia is 35.5GB if you're coming from Sierra, it can go up to 44.5GB if coming from an older version
# This value is acconting for the required space and the size of the installer (almost 13GB)
REQUIREDMINIMUMRAM=4

if [[ "$OSVERSIONMAJOR" -ge 16 ]]; then
	# For Sierra and higher required space is 12.3GB for the installer and 26GB for required disk space for installation which equals to 38GB, 42GB is giving a bit of extra free space for safety
	REQUIREDMINIMUMSPACE=42
else
	# For pre-Sierra required space is 12.3GB for the installer and 44.5GB for required disk space for installation which equals to 56.8GB, 60GB is giving a bit of extra free space for safety
	REQUIREDMINIMUMSPACE=60
fi

#########################################################################################
############### DO NOT CHANGE UNLESS NEEDED
#########################################################################################

# Default values for Compatibility is false
COMPATIBILITY="False"

#########################################################################################
############### Let's go!
#########################################################################################

# Checks if computer meets pre-requisites for Sequoia
# This also means that if the computer is already running Sequoia it will be marked as false
# You can change this behaviour by modifying the 23 into a 24
if [[ "$OSVERSIONMAJOR" -ge 13 && "$OSVERSIONMAJOR" -le 23 ]]; then

	# Transform GB into Bytes
	GIGABYTES=$((1024 * 1024 * 1024))
	MINIMUMRAM=$(($REQUIREDMINIMUMRAM * $GIGABYTES))
	MINIMUMSPACE=$(($REQUIREDMINIMUMSPACE * $GIGABYTES))

	# Gets the Model Identifier, splits name and major version
	MODELIDENTIFIER=$(/usr/sbin/sysctl -n hw.model)
	MODELNAME=${MODELIDENTIFIER//[^a-zA-Z]/}
	MODELVERSION=$(echo "$MODELIDENTIFIER" | sed -e 's/[^0-9,]//g' -e 's/,//')

	# Gets amount of memory installed
	MEMORYINSTALLED=$(/usr/sbin/sysctl -n hw.memsize)

	# Gets free space on the boot drive
	FREESPACE=$(diskutil info / | awk -F '[()]' '/Free Space|Available Space/ {print $2}' | sed -e 's/\ Bytes//')

	# Checks if computer meets pre-requisites for Sequoia
	if [[ "$MODELNAME" == "iMac" && "$MODELVERSION" -ge 190 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
		COMPATIBILITY="True"
	elif [[ "$MODELNAME" == "iMacPro" && "$MODELVERSION" -ge 10 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
		COMPATIBILITY="True"
	elif [[ "$MODELNAME" == "Macmini" && "$MODELVERSION" -ge 80 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
		COMPATIBILITY="True"
	elif [[ "$MODELNAME" == "MacPro" && "$MODELVERSION" -ge 70 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
	    COMPATIBILITY="True"
	elif [[ "$MODELNAME" == "MacBookAir" && "$MODELVERSION" -ge 90 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
	    COMPATIBILITY="True"
	elif [[ "$MODELNAME" == "MacBookPro" && "$MODELVERSION" -ge 150 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
	    COMPATIBILITY="True"
	elif [[ "$MODELNAME" == "Mac" && "$MODELVERSION" -ge 130 && "$MEMORYINSTALLED" -ge "$MINIMUMRAM" && "$FREESPACE" -ge "$MINIMUMSPACE" ]]; then
	    COMPATIBILITY="True"		    
	fi
	# Outputs result
	echo "<result>$COMPATIBILITY</result>"
else
	echo "<result>$COMPATIBILITY</result>"
	exit $?
fi
