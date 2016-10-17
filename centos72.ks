install
text
keyboard us
lang en_US.UTF-8
skipx
network --device eth0 --bootproto dhcp
rootpw CK2016@chukong-inc.com
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --disabled
services --enabled=NetworkManager,sshd
timezone --utc Asia/Chongqing --isUtc --nontp
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200"
zerombr
clearpart --all --initlabel
part / --fstype ext4 --size=19768 --grow
reboot
%post
chmod 0655 /etc/rc.d/rc.local
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
      sed -i "s/^HOSTNAME=.*\$/HOSTNAME=\$TEMP_HOST/g" /etc/sysconfig/network
      /bin/ hostnamectl --static set-hostname \$TEMP_HOST
      /bin/hostnamectl set-hostname \$TEMP_HOST
     # /bin/hostname \$TEMP_HOST
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
    rm -rf /var/log/yum.log
    rm -rf /var/lib/yum/*
    rm -rf /root/install.log
    rm -rf /root/install.log.syslog
    rm -rf /root/anaconda-ks.cfg
    rm -rf /var/log/anaconda*
    rm -rf /tmp/yum.log
    rm -rf /tmp/ks-script-*
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
%end

%packages --nobase --excludedocs
openssh-server
openssh-clients
acpid
wget
vim
%end
