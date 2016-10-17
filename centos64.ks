install
text
key --skip
keyboard us
lang en_US.UTF-8
skipx
network --device eth0 --bootproto dhcp
rootpw denglei2016
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --disabled
timezone --utc Asia/Chongqing
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200"
zerombr yes
clearpart --all

part / --fstype ext4 --size=19768 --grow
reboot
%post
rm -rf /etc/yum.repos.d/*
cat <<EOL > /etc/yum.repos.d/CentOS6.repo
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-6 - Base - mirrors.ustc.edu.cn
baseurl=http://mirrors.ustc.edu.cn/centos/6/os/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=os
gpgcheck=0
gpgkey=http://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-6

#released updates
[updates]
name=CentOS-6 - Updates - mirrors.ustc.edu.cn
baseurl=http://mirrors.ustc.edu.cn/centos/6/updates/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=updates
gpgcheck=1
gpgkey=http://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-6

#additional packages that may be useful
[extras]
name=CentOS-6 - Extras - mirrors.ustc.edu.cn
baseurl=http://mirrors.ustc.edu.cn/centos/6/extras/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=extras
gpgcheck=1
gpgkey=http://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-6

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-6 - Plus - mirrors.ustc.edu.cn
baseurl=http://mirrors.ustc.edu.cn/centos/6/centosplus/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=http://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-6

[epel]
name=CentOS-6 - Epel - mirrors.ustc.edu.cn
baseurl=http://mirrors.ustc.edu.cn/epel/6/\$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=6&arch=\$basearch&repo=contrib
gpgcheck=1
enabled=1
gpgkey=http://mirrors.ustc.edu.cn/epel/RPM-GPG-KEY-EPEL-6
EOL
yum clean all
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
cat >> /etc/rc.local << EOF
/bin/bash /usr/local/bin/instance_init.sh
EOF
cat >/usr/local/bin/instance_init.sh<<EOF
#!/bin/bash
if [ ! -d /root/.ssh ]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
fi
# Fetch public key using HTTP
ATTEMPTS=30
FAILED=0
while [ ! -f /root/.ssh/authorized_keys ]; do
  curl -f http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > /tmp/metadata-key 2>/dev/null
  if [ \$? -eq 0 ]; then
    cat /tmp/metadata-key >> /root/.ssh/authorized_keys
    chmod 0600 /root/.ssh/authorized_keys
    restorecon /root/.ssh/authorized_keys
    rm -f /tmp/metadata-key
    echo "Successfully retrieved public key from instance metadata"
    echo "*****************"
    echo "AUTHORIZED KEYS"
    echo "*****************"
    cat /root/.ssh/authorized_keys
    echo "*****************"

    curl -f http://169.254.169.254/latest/meta-data/reservation-id > /tmp/metadata-hostname 2>/dev/null
    if [ \$? -eq 0 ]; then
      TEMP_HOST=\$(cat /tmp/metadata-hostname)
      #TEMP_HOST=\$(cat /tmp/metadata-hostname|awk -F '.novalocal' '{print \$1}')
      sed -i "s/^HOSTNAME=.*\$/HOSTNAME=\$TEMP_HOST/g" /etc/sysconfig/network
      /bin/hostname \$TEMP_HOST
      echo "Successfully retrieved hostname from instance metadata"
      echo "*****************"
      echo "HOSTNAME CONFIG"
      echo "*****************"
      cat /etc/sysconfig/network
      echo "*****************"

    else
      echo "Failed to retrieve hostname from instance metadata.  This is a soft error so we'll continue"
    fi
    rm -f /tmp/metadata-hostname
    sed -i '/instance_init/d' /etc/rc.d/rc.local
    rm -rf /usr/local/bin/instance_init.sh
  else
    FAILED=\$((\$FAILED + 1))
    if [ \$FAILED -ge \$ATTEMPTS ]; then
      echo "Failed to retrieve public key from instance metadata after \$FAILED attempts, quitting"
      break
    fi
      echo "Could not retrieve public key from instance metadata (attempt #\$FAILED/\$ATTEMPTS), retrying in 5 seconds..."
      sleep 5
    fi
done
EOF
rm -rf /var/log/yum.log
rm -rf /var/lib/yum/*
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*
rm -rf /tmp/yum.log
rm -rf /tmp/ks-script-*
%packages --nobase --excludedocs
openssh-server
openssh-clients
python
acpid
wget
vim
