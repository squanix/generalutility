#!/bin/bash

# while-menu-dialog: a menu driven system information program

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --msgbox "$result" 0 0
}

display_result_Spoofing() {
  dialog --title "You Change the IP or MAC" \
    --no-collapse \
    --yesno "Are you sure want to change your IP or MAC address to $1 ?" 0 0 \
    
    response=$?
    case $response in
       0) 
          spoffing_network $1
          ;;
       1) 
          networking_choice
          ;;
    esac
}

networking_choice() {
   exec 3>&1
   networking_choice=$(dialog \
    --title "Servicing" \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Wlan Up Networking" \
    "2" "Wlan Down Networking" \
    "3" "Spoofing MAC or IP address" \
    2>&1 1>&3)
    case $networking_choice in 
        1 ) 
            network up
            ;;
        2 ) 
            network down
            ;;
        3 ) 
            spoffing
            ;;
    esac
    
}

network() {
    sudo ip link set wlan0 "$1"
}

spoffing() {
    exec 3>&1
    resultipmac=$(dialog --title "Input the IP or MAC address" \
        --cancel-label "Exit" \
        --inputbox "Enter IP or MAC" 0 0 2>&1 1>&3)
    
    display_result_Spoofing $resultipmac
 
}

spoffing_network() {
    network down
    sudo sudo ip link set wlan0 address "$1"
    network up
}

service_choice() {
   exec 3>&1
   selection_choice=$(dialog \
    --title "Servicing" \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Start services" \
    "2" "Stop services" \
    "3" "Enable service" \
    "4" "Disable service" \
    "5" "See the running services" \
    "6" "See the dead services" \
    "7" "See the enabled services" \
    "8" "See the disabled service" \
    2>&1 1>&3)
    case $selection_choice in 
       1 )
          service start
          ;;
       2 )
          service stop
          ;;
       3 )
          service enable
          ;;
       4 )
          service disable
          ;;
       5 )
          result_list=$(systemctl list-units --type=service --state=running)
          list_service
          ;;
       6 )
          result_list=$(systemctl list-units --type=service --state=dead)
          list_service
          ;;
       7 )
          result_list=$(systemctl list-unit-files --state=enabled)
          list_service 
          ;;
       8 )
          result_list=$(systemctl list-unit-files --state=disabled)
          list_service
          ;;
    esac
}

list_service() {
   dialog --title "Service" \
    --no-collapse \
    --msgbox "$result_list" 0 0
}

sudo_access_dialog() {
   dialog --title "Grant the Access" \
   --no-collapse \
   --msgbox "You must have the root access!" 0 0 \
#   $(sudo -i)
}

service() {
   exec 3>&1
   selection_service=$(dialog \
    --title "Servicing" \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Network Manager" \
    "2" "CUPS" \
    "3" "WPA Supplicant" \
    "4" "TLP" \
    2>&1 1>&3)
    case $selection_service in
       1 ) 
          start_and_stop_service "$1" NetworkManager
          ;;
       2 )
          start_and_stop_service "$1" cups
          ;;
       3 )
          start_and_stop_service "$1" wpa_supplicant
          ;;
       4 )
          start_and_stop_service "$1" tlp
          ;;
    esac
}

start_and_stop_service() {
   sudo systemctl "$1" "$2"
}

conserv_menu() {
  exec 3>&1
  selection_Consv=$(dialog \
    --title "$1" \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Enable Conservation battery" \
    "2" "Disable Conservation battery" \
    2>&1 1>&3)
    case $selection_Consv in
      1 ) 
       change_consv 1
       ;;
      2 )
       change_consv 0
       ;;
    esac
}

change_consv() {
  echo "$1"| sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
}

while true; do
  exec 6>&1
  selection=$(dialog \
    --backtitle "System Information" \
    --title "Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Display System Information" \
    "2" "Display Disk Space" \
    "3" "Display Home Space Utilization" \
    "4" "Display Conservation Battery" \
    "5" "Service Control" \
    "6" "Networking" \
    2>&1 1>&6)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    1 )
      result=$(echo "Hostname: $HOSTNAME"; uptime)
      display_result "System Information"
      ;;
    2 )
      result=$(df -h)
      display_result "Disk Space"
      ;;
    3 )
      if [[ $(id -u) -eq 0 ]]; then
        result=$(du -sh /home/* 2> /dev/null)
        display_result "Home Space Utilization (All Users)"
      else
        result=$(du -sh $HOME 2> /dev/null)
        display_result "Home Space Utilization ($USER)"
      fi
      ;;
    4 )
      if [[ $(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode) -eq 1 ]]; then
        conserv_menu "Conservation Battery is Enable"
      else
        conserv_menu "Conservation Battery is Disable"
      fi
      ;;
    5 )
      service_choice
      ;;
    6 )
      networking_choice 
      ;;
  esac
done
