#! /bin/sh

change_param_to_usb() {

  # TEMPLATE: change_param

  # DEFAULT VALUE OF /boot/cmdline.txt:
  # dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=7d8d8169-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait

  #sed "s/root=[^ ]*/root=\/dev\/sda2/" /boot/cmdline.txt

  # Регулярные выражения http://citforum.ru/operating_systems/articles/tut_6.shtml http://qaru.site/questions/21734/non-greedy-regex-matching-in-sed

  local KEY=root
  # local PARAM="\/dev\/disk\/by-path\/platform-3f980000.usb-usb-0:1.2:1.0-scsi-0:0:0:0-part2 rootdelay=5"
  local VALUE="/dev/sda2"
  local FILE=/boot/cmdline.txt
  local DELIMITER=" "
  local SEPARATOR="="

  sed -i "s/$KEY$SEPARATOR[^$DELIMITER]*/$KEY$SEPARATOR$VALUE/" $FILE
}

change_param_to_sd() {

  # TEMPLATE: change_param

  # DEFAULT VALUE OF /boot/cmdline.txt:
  # dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=7d8d8169-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait

  #sed "s/root=[^ ]*/root=\/dev\/sda rootdelay=5/" /boot/cmdline.txt

  # Регулярные выражения http://citforum.ru/operating_systems/articles/tut_6.shtml http://qaru.site/questions/21734/non-greedy-regex-matching-in-sed

  local KEY=root
  # local PARAM="\/dev\/disk\/by-path\/platform-3f980000.usb-usb-0:1.2:1.0-scsi-0:0:0:0-part2 rootdelay=5"
  local VALUE="/dev/mmcblk0p2"
  local FILE=/boot/cmdline.txt
  local DELIMITER=" "
  local SEPARATOR="="

  sed -i "s/$KEY$SEPARATOR[^$DELIMITER]*/$KEY$SEPARATOR$VALUE/" $FILE
}

delete_param() {

  # TEMPLATE: delete_param $KEY

  # Не удалеяет первый параметр тк нет пробела
  # При повторяющихся параметрах удаляет последний
  # Не удаляет параметр без знака равенства

  local FILE=/boot/cmdline.txt
  local DELIMITER=" "
  local SEPARATOR="="

  sed -i "s/ $1$SEPARATOR[^$DELIMITER]*//" $FILE
}

burn_image() {

  # STATIC
  # TEMPLATE: burn_image $IMAGE_PATH $MICROSD_DEV

  echo "Burn image"
  dd if=$1 of=$2

}

burn_and_reboot() {

  # STATIC
  # TEMPLATE: burn_and_reboot $IMAGE_PATH $MICROSD_DEV

  burn_image $1 $2 \
    && reboot
}

copy_orig() {

  echo "Copy from orig.img"
  if [ ! -e "/home/pi/tester/temp/urpylka-test.img" ];
  then cp /home/pi/tester/temp/2017-11-29-raspbian-stretch-lite.img $1
  fi
}

change_image() {

  local PREFIX_PATH=/mnt
  local IMAGE=$1

  local UUID_BOOT=CDD4-B453
  local UUID_ROOTFS=72bfc10d-73ec-4d9e-a54a-1cc507ee7ed2

  local DEV_BOOT=/dev/disk/by-uuid/$UUID_BOOT
  local DEV_ROOTFS=/dev/disk/by-uuid/$UUID_ROOTFS

  local EXECUTE_FILE=/home/pi/tester/comeback.sh

  /home/pi/tester/image-config.sh execute $IMAGE $PREFIX_PATH $DEV_ROOTFS $DEV_BOOT $EXECUTE_FILE
}

downloader() {
  echo $1
  echo "download"
  wget -O /home/pi/tester/temp/my_local_filename.img $1
  echo "end download"
}

yadisk_path() {
  echo $1
  echo "yadisk"
  curl -L $(yadisk-direct $1) -o /home/pi/tester/temp/my_local_filename.img
  echo "end yadisk"
}

all() {

PATH_TO_DOWNLOAD=
PATH_TO_IMAGE=/home/pi/tester/temp/my_local_filename.img

  #downloader $PATH_TO_DOWNLOAD \
  copy_orig $PATH_TO_IMAGE \
    && change_image $PATH_TO_IMAGE \
    && burn_and_reboot $PATH_TO_IMAGE "/dev/mmcblk0"
}



if [ $(whoami) != "root" ];
then echo "" \
  && echo "********************************************************************" \
  && echo "******************** This should be run as root ********************" \
  && echo "********************************************************************" \
  && echo "" \
  && exit 1
fi

echo "\$#: $#"
echo "\$1: $1"
echo "\$2: $2"

case "$1" in
  all)
    all;;

  change_param)
    change_param;;

  delete_param) # delete_param $KEY
    delete_param $2;;

  *)
    echo "Enter one of: change_param, delete_param";;
esac
