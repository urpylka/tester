#!/bin/sh

echo "Create /boot/ssh"
touch /boot/ssh

echo "Create /home/pi/.ssh/authorized_keys2"
mkdir /home/pi/.ssh
echo "RSA" >> /home/pi/.ssh/authorized_keys2
chown -Rf pi:pi /home/pi

echo "Change /etc/wpa_supplicant/wpa_supplicant.conf"
echo "
network={
  ssid=\"SSID\"
  psk=PSK
}
" >> /etc/wpa_supplicant/wpa_supplicant.conf



echo -e "\033[0;31m\033[1m$(date) | #8 Write magic comeback-script /etc/rc.local\033[0m\033[0m"

COMEBACK="sudo sed -i.OLD \"s/root=[^ ]*/root=\\\/dev\\\/sda2/g\" /boot/cmdline.txt && sudo sed -i '/sudo sed/d' /etc/rc.local"

sed -i "19a$COMEBACK" /etc/rc.local

echo -e "\033[0;31m\033[1m$(date) | #9 End of install programs\033[0m\033[0m"
