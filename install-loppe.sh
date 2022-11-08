#!/usr/bin/env bash

# Author: Dmitri Popov, dmpop@linux.com

#######################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################

if [ ! -x "$(command -v apt)" ]; then
        echo "Looks like it's not a Debian-based system."
        exit 1
fi

if [[ $EUID -eq 0 ]]; then
        echo "Run the script as a regular user"
        exit 1
fi

cd
sudo apt update
sudo apt upgrade -y
sudo apt install -y git gphoto2 screen usbmount exfat-fuse exfat-utils
sudo apt autoremove -y

git clone https://github.com/dmpop/loppe.git
chmod +x $HOME/loppe/*.sh
sudo ln -s $HOME/loppe/loppe.sh /usr/local/bin/loppe
sudo mv /etc/usbmount/usbmount.conf /etc/usbmount/usbmount.conf.bak
sudo bash -c "cat > /etc/usbmount/usbmount.conf" << EOL
ENABLED=1
MOUNTPOINTS="/media/usb0 /media/usb1 /media/usb2 /media/usb3 /media/usb4"
FILESYSTEMS="vfat exfat ext2 ext3 ext4 hfsplus"
MOUNTOPTIONS="sync,noexec,nodev,noatime,nodiratime,uid=1000,gid=1000"
FS_MOUNTOPTIONS=" "
VERBOSE=no
EOL
crontab -l | {
        cat
        echo "@reboot sudo /home/"$USER"/loppe/loppe.sh"
        } | crontab

# Configure Samba
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.orig
pw="loppe"
(
    echo $pw
    echo $pw
) | sudo smbpasswd -s -a "$USER"
sudo sh -c "echo '[Loppe]' >> /etc/samba/smb.conf"
sudo sh -c "echo 'comment = Loppe' >> /etc/samba/smb.conf"
sudo sh -c "echo 'path = /home/$USER/BACKUP' >> /etc/samba/smb.conf"
sudo sh -c "echo 'browseable = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'force user = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'force group = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'admin users = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'writeable = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'read only = no' >> /etc/samba/smb.conf"
sudo sh -c "echo 'guest ok = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'create mask = 0777' >> /etc/samba/smb.conf"
sudo sh -c "echo 'directory mask = 0777' >> /etc/samba/smb.conf"
sudo samba restart

echo "-------------------------------------"
echo "All done! The system will reboot now."
echo "-------------------------------------"
sudo reboot
