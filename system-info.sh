#!/bin/bash
################################################################################
#               system-info.sh                                                 #
#   Modification from orginal [mymotd](https://www.both.org/downloads/mymotd)  #
#                                                                              #
# This bash shell extracts various interesting bits of information about the   #
# Linux host and the operating system itself. It prints this data to STDOUT    #
# in a nice looking format. The results can also be redirected to the          #
# /etc/motd file to create an informational message of the day.                #
#                                                                              #
# This script is a rewrite of the original createMOTDlinux. It does the same   #
# thing but is much cleaner and uses techniques I have learned since I wrote   #
# the original.                                                                #
#                                                                              #
#                                                                              #
#                                                                              #
# Change History                                                               #
# 01/08/2018  David Both    Original code.                                     #
# 04/01/2018  David Both    Use lscpu instead of accessing data in the         #
#                           /proc/cpuinfo file. Removed old variables.         #
#                           Add some new CPU data to that section.             #
# 04/02/2018  David Both    Changed CPU and Core variables to be aligned with #
#                           the Intel meaning.                                 #
# 03/03/2022  David Both    Fix problems with CPU and motherboard data.        #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
#                                                                              #
################################################################################
################################################################################
################################################################################
#                                                                              #
#  Copyright (C) 2007, 2018, 2022 David Both                                   #
#  LinuxGeek46@both.org                                                        #
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
#                                                                              #
#  You should have received a copy of the GNU General Public License           #
#  along with this program; if not, write to the Free Software                 #
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   #
#                                                                              #
################################################################################
################################################################################
################################################################################

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "                  mymotd"
   echo "Generate a /etc/MOTD file that contains information about the system"
   echo "hardware and the installed version of Linux."
   echo
   echo "Syntax:  mymotd [-g|h|v|V]"
   echo "options:"
   echo "g     Print the GPL license notification."
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "V     Print software version and exit."
   echo
}

################################################################################
# Print the GPL license header                                                 #
################################################################################
gpl()
{
   echo
   echo "################################################################################"
   echo "#  Copyright (C) 2007, 2018, 2022  David Both                                  #"
   echo "#  http://www.both.org                                                         #"
   echo "#                                                                              #"
   echo "#  This program is free software; you can redistribute it and/or modify        #"
   echo "#  it under the terms of the GNU General Public License as published by        #"
   echo "#  the Free Software Foundation; either version 2 of the License, or           #"
   echo "#  (at your option) any later version.                                         #"
   echo "#                                                                              #"
   echo "#  This program is distributed in the hope that it will be useful,             #"
   echo "#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #"
   echo "#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #"
   echo "#  GNU General Public License for more details.                                #"
   echo "#                                                                              #"
   echo "#  You should have received a copy of the GNU General Public License           #"
   echo "#  along with this program; if not, write to the Free Software                 #"
   echo "#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   #"
   echo "################################################################################"
   echo
}

################################################################################
# Quit nicely with messages as appropriate                                     #
################################################################################
Quit()
{
   if [ $verbose = 1 ]
      then
      if [ $error = 0 ]
         then
         echo "Program terminated normally"
      else
         echo "Program terminated with error ID $ErrorMsg";
      fi
   fi
   exit $error
}

################################################################################
# Display verbose messages in a common format                                  #
################################################################################
PrintMsg()
{
   if  [ $verbose = 1 ] && [ -n "$Msg" ]
   then
      echo "########## $Msg ##########"
      # Set the message to null
      Msg=""
   fi
}

################################################################################
# Convert KB to GB                                                             #
################################################################################
kb2gb()
{
   # Convert KBytes to Giga using 1024
   echo "scale=3;$number/1024/1024" | bc
}


################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################
# Set initial variables
badoption=0
BIOSdate=""
CPUArch=""
CPUdata=""
CPUModel=""
CPUs=0
CurrMHz=0
Date=""
Distro=-""
DistroArch=""
error=0
host=""
HostArch=""
HyperThreading="No"
InstallDate=""
MachineType=""
MaxMHz=0
MinMHz=0
mem=0
MotherboardMfr=""
MotherboardModel=""
MotherboardSerial=""
number=0
NumCores=0
Cores=0
Package=0
PhysicalChips=0
Siblings=0
swap=0
SystemSerial=""
SystemUUID=""
Threading=""
Threads=0
verbose=0
Version=01.00.04


#---------------------------------------------------------------------------
# Check for root. Delete if necessary.

if [ `id -u` != 0 ]
then
   echo ""
   echo "You must be root user to run this program"
   echo ""
   Quit 1
fi

#---------------------------------------------------------------------------
# Check for Linux

if [[ "$(uname -s)" != "Linux" ]]
then
   echo ""
   echo "This script only runs on Linux -- OS detected: $(uname -s)."
   echo ""
   Quit 1
fi
#---------------------------------------------------------------------------

################################################################################
# Process the input options. Add options as needed.                            #
################################################################################
# Get the options
while getopts ":ghrvV" option; do
   case $option in
      g) # display GPL
         gpl
         Quit;;
      h) # display Help
         Help
         Quit;;
      v) # Set verbose mode
         verbose=1;;
      V) # Print the software version
         echo "Version = $Version"
         Quit;;
     \?) # incorrect option
         badoption=1;;
   esac
done

if [ $badoption = 1 ]
then
   echo "ERROR: Invalid option"
   Help
   verbose=1
   error=1
   ErrorMsg="10T"
   Quit $error
fi

################################################################################
################################################################################
# The main body of your program goes here.
################################################################################
################################################################################

# Get the date
Date=`date`
# Get the hostname info
host=`hostname`

################################################################################
# Start printing the data using printf to make it pretty                       #
################################################################################
printf "#######################################################################\n"
printf "# MOTD for $Date\n"
printf "# HOST NAME: \t\t$host \n"

################################################################################
# Is this a VirtualBox, VMWare, or Physical Machine.                           #
################################################################################
if dmesg | grep -i "VBOX HARDDISK" > /dev/null
then
   MachineType="VM running under VirtualBox."
elif dmesg | grep -i "vmware" > /dev/null
then
   MachineType="VM running under VMWare."
else
   MachineType="physical machine."
fi
printf "# Machine Type: \t$MachineType\n"

# Get the host physical architecture
HostArch=`echo $HOSTTYPE | tr [:lower:] [:upper:]`
printf "# Host architecture: \t$HostArch\n"

################################################################################
# Get the system serial number and UUID                                        #
################################################################################
printf "#----------------------------------------------------------------------\n"
SystemSerial=`dmidecode -t 1 | grep "Serial Number" | awk -F: '{print $2}' | sed -e "s/^\s* //"`
printf "# System Serial No.:\t$SystemSerial\n"
SystemUUID=`dmidecode -t 1 | grep "UUID" | awk -F: '{print $2}' | sed -e "s/^\s* //"` 
printf "# System UUID: \t\t$SystemUUID\n"

################################################################################
# Get the motherboard information                                              #
################################################################################
MotherboardMfr=`dmidecode -t 2 | grep -i Manufacturer | awk -F: '{print $2}' | sed -e "s/^ //"`
printf "# Motherboard Mfr: \t$MotherboardMfr\n"
MotherboardModel=`dmidecode -t 2 | grep -i Name | awk -F: '{print $2}' | sed -e "s/^ //"`
printf "# Motherboard Model: \t$MotherboardModel\n"
MotherboardSerial=`dmidecode -t 2 | grep -i Serial | awk -F: '{print $2}' | sed -e "s/^ //"`
printf "# Motherboard Serial: \t$MotherboardSerial\n"
BIOSdate=`dmidecode -t 0 | grep -i "Release Date" | awk -F: '{print $2}' | sed -e "s/^ //"`
printf "# BIOS Release Date: \t$BIOSdate\n"
printf "#----------------------------------------------------------------------\n"

################################################################################
# Get the CPU information                                                      #
################################################################################
# Starting with the specific hardware model
CPUModel=`lscpu | grep -i "^model name" | head -n 1 | cut -d : -f 2 | sed -e "s/^\s* //"`
printf "# CPU Model:\t\t$CPUModel\n"

################################################################################
# Get some CPU details.                                                        #
################################################################################
# Get number of actual physical chips
PhysicalChips=`lscpu | grep "^Socket(s)" | awk '{print $2}'`
if [ $PhysicalChips -eq 0 ]
then
   let PhysicalChips=1
fi
# Get the total number of cores and CPUs. 
Cores=`lscpu | grep "^Core(s) per socket" | head -n 1 | cut -d : -f 2 | sed -e "s/^\s* //"`
CPUs=`lscpu | grep "^CPU(s)" | head -n 1 | cut -d : -f 2 | sed -e "s/^\s* //"`

# Do we have HyperThreading
Threading=`lscpu | grep "^Thread(s) per core" | head -n 1 | cut -d : -f 2 | sed -e "s/^\s* //"`
if [ $Threading -gt 1 ]
then
   # Yes we have HyperThreading
   HyperThreading="Yes"
   # Get total threads
   Threads=`lscpu | grep "^CPU(s)" | head -n 1 | cut -d : -f 2 | sed -e "s/^\s* //"`
fi

# Get CPU speed info
CurrMHz=`cat /proc/cpuinfo | grep "cpu MHz" | head -n 1 | awk '{print $4}'`
MaxMHz=`lscpu | grep "^CPU max MHz:" | awk -F: '{print $2}' | sed -e "s/^\s* //"`
MinMHz=`lscpu | grep "^CPU min MHz:" | awk -F: '{print $2}' | sed -e "s/^\s* //"`


# Now Cores per package - Each core can have multiple Cores
# We are assuming each package has the same number of cores
case "$Cores" in
   1) Package="Single Core";;
   2) Package="Dual Core";;
   4) Package="Quad Core";;
   6) Package="Six Core";;
   8) Package="Eight Core";;
  10) Package="Ten Core";;
  12) Package="Twelve Core";;
  14) Package="Fourteen Core";;
  16) Package="Sixteen Core";;
  18) Package="Eighteen Core";;
  20) Package="Twenty Core";;
  24) Package="Twenty-four Core";;
  26) Package="Twenty-six Core";;
  28) Package="Twenty-eight Core";;
  30) Package="Thirty Core";;
  32) Package="Thirty-two Core";;
   *) Package="Single Core"
      Cores=1;;
esac

# Get the CPU architecture which can be different from the host architecture
CPUArch=`arch`
# Now lets put some of this together to make printing easy
CPUdata="$PhysicalChips $Package package with $CPUs CPUs"

# Let's print what we have
printf "# CPU Data:\t\t$CPUdata\n"
printf "# CPU Architecture:\t$CPUArch\n"
printf "# HyperThreading:\t$HyperThreading\n"
printf "# Max CPU MHz:\t\t$MaxMHz\n"
printf "# Current CPU MHz:\t$CurrMHz\n"
printf "# Min CPU MHz:\t\t$MinMHz\n"
printf "#----------------------------------------------------------------------\n"

################################################################################
# Memory and Swap data                                                         #
################################################################################
# Get memory size in KB.
number=`grep MemTotal /proc/meminfo | awk '{print $2}'`
# Convert to GB
mem=`kb2gb`
# Get swap size in KB
number=`grep SwapTotal /proc/meminfo | awk '{print $2}'`
# Convert to GB
swap=`kb2gb`

printf "# RAM:\t\t\t$mem GB\n"
printf "# SWAP:\t\t\t$swap GB\n"
printf "#----------------------------------------------------------------------\n"


# Get the installation Date
InstallDate=`dumpe2fs $(findmnt / -no source) 2>/dev/null | grep 'Filesystem created:' | cut -d ':' -f 2`
printf "# Install Date:\t\t$InstallDate\n"

################################################################################
# Get the Linux distribution information                                       #
################################################################################
# Get the Distro version
# use substitutions to get it to say what we want
Distro=`lsb_release -a  2> /dev/null | grep Description | cut -d ':' -f 2`
# Replace the text distro name with acronym
#Distro=`echo $Distro | sed -e 's/Red Hat Enterprise Linux/RHEL/g' -e 's/Centos/CEL/'`
#Distro=`echo $Distro | sed s/" AS "/" "/g | sed s/" [cC]lient "/" "/g | sed s/" [sS]erver "/" "/g`
#Distro=`echo $Distro | sed s/" [rR]elease "/" "/g`

# Now lets find whether Distro is I686 (32-bit) or X86_64 (64 bit)
if uname -m | grep x86_64 > /dev/null
then
   DistroArch="X86_64"
else
   DistroArch="I686"
fi
printf "# Linux Distribution:\t$Distro $DistroArch\n"

# And print the kernel version.
printf "# Kernel Version:\t`uname -r`\n"
printf "#----------------------------------------------------------------------\n"

printf "# Disk Partition Info\n"
df -hP | grep -v tmpfs | awk -F ^ '{print "# "$1}'
# fdisk -l 2>/dev/null | egrep "Disk /dev/[hsm][dr][a-z]" | uniq | awk '{print "# "$2"\t\t"$3" "$4}' | sort | sed s/,// 
################################################################################
# If there is LVM on this system, display it                                   #
################################################################################
if pvs | grep lvm2 >/dev/null
then
   printf "#----------------------------------------------------------------------\n"
   printf "# LVM Physical Volume Info\n"
   printf "# PV\t\tVG\t\tFmt\tAttr\tPSize\tPFree\n"
   pvs | grep -v PV | sort | awk '{print "# "$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}'
fi
printf "#######################################################################\n"
printf "# Note: This MOTD file gets updated automatically every day.\n"
printf "#       Changes to this file will be automatically overwritten!\n"
printf "#######################################################################\n"

Quit

################################################################################
# End of program
################################################################################

