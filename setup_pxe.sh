sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
yum install httpd -y
yum install tftp-server -y
yum install dhcp-server -y
echo "Downloading CentOS image..."
#wget https://mirror.sale-dedic.com/centos/8.4.2105/isos/x86_64/CentOS-8.4.2105-x86_64-dvd1.iso
mount -t iso9660 /vagrant/CentOS-8.4.2105-x86_64-dvd1.iso /mnt -o loop,ro
mkdir /iso
echo "Unpacking image..."
cp -r /mnt/* /iso
cp /vagrant/ks.cfg /iso/
chmod -R 755 /iso
echo -e "Alias /centos8 /iso\n<Directory "/iso"> \n\tOptions Indexes FollowSymLinks \n\tRequire all granted \n</Directory>" > /etc/httpd/conf.d/pxeboot.conf
mkdir /var/lib/tftpboot/pxelinux.cfg
echo -e "default menu.c32
prompt 0
timeout 150
ONTIME local
menu title OTUS PXE Boot Menu
label 1
menu label ^ Graph install CentOS 8.4
kernel /vmlinuz
initrd /initrd.img
append ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8
label 2
menu label ^ Text install CentOS 8.4
kernel /vmlinuz
initrd /initrd.img
append ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8 text
label 3
menu label ^ rescue installed system
kernel /vmlinuz
initrd /initrd.img
append ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8 rescue
label 4
menu label ^ Auto-install CentOS 8.4
#Загрузка данного варианта по умолчанию
menu default
kernel /vmlinuz
initrd /initrd.img
append ip=enp0s3:dhcp inst.ks=http://10.0.0.20/centos8/ks.cfg inst.repo=http://10.0.0.20/centos8/" > /var/lib/tftpboot/pxelinux.cfg/default
rpm2cpio /iso/BaseOS/Packages/syslinux-tftpboot-6.04-5.el8.noarch.rpm | cpio -dimv
cp tftpboot/{pxelinux.0,ldlinux.c32,libmenu.c32,libutil.c32,menu.c32,vesamenu.c32} /var/lib/tftpboot/
cp /iso/images/pxeboot/{initrd.img,vmlinuz} /var/lib/tftpboot/
echo -e 'option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;
subnet 10.0.0.0 netmask 255.255.255.0 {
        range 10.0.0.100 10.0.0.120;
        class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          next-server 10.0.0.20;
          filename "pxelinux.0";
        }
       }' > /etc/dhcp/dhcpd.conf

systemctl enable httpd.service
systemctl enable tftp.service
systemctl enable dhcpd
systemctl restart httpd.service
systemctl restart tftp.service
systemctl restart dhcpd




