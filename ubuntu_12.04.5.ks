d-i debian-installer/locale string en_US
d-i console-setup/ask_detect boolean false
d-i console-setup/layoutcode string us

d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain
d-i netcfg/wireless_wep string

d-i clock-setup/utc boolean true
d-i time/zone string Asia/Shanghai

d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select home
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password password denglei2016
d-i passwd/root-password-again password denglei2016

tasksel tasksel/first multiselect standard
d-i pkgsel/include/install-recommends boolean true
d-i pkgsel/include string openssh-server curl

d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true

d-i apt-setup/security_host string
base-config apt-setup/security-updates boolean false

ubiquity ubiquity/summary note
ubiquity ubiquity/reboot boolean true

d-i finish-install/reboot_in_progress note

# In Debian/Ubuntu, ssh keys are generated at package install time.  Because
# the disk image may be cached, we need to remove the ssh keys, but this means
# that ssh'ing into the server won't work later.  So we remove the keys, but
# setup a service that will generate the keys on boot if necessary.
d-i preseed/late_command string \
    in-target rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_dsa_key.pub /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key.pub ; \
    echo '#! /bin/sh' > /target/etc/init.d/oz-generate-ssh ; \
    echo '#' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# Debian/Ubuntu generate ssh host keys at package installation time.' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# This is problematic for Oz, since the final disk image may be cached' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# and reused, leading to duplicate host keys.  To work around this, Oz' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# deletes the SSH host keys at the end of installation.  This solves' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# the above problem, but introduces the problem of having no way to' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# SSH into the machine without manual intervention.  This service checks' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# to see if host keys are already installed, and if not, recreates them.' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '# Note that after the very first boot, this service could be removed.' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '#' >> /target/etc/init.d/oz-generate-ssh ; \
    echo 'case "$1" in' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '  start)' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '      [ -r /etc/ssh/ssh_host_rsa_key ] || /usr/sbin/dpkg-reconfigure openssh-server' >> /target/etc/init.d/oz-generate-ssh ; \
    echo '      ;;' >> /target/etc/init.d/oz-generate-ssh ; \
    echo 'esac' >> /target/etc/init.d/oz-generate-ssh ; \
    echo 'exit 0' >> /target/etc/init.d/oz-generate-ssh ; \
    in-target chmod 755 /etc/init.d/oz-generate-ssh ; \
    in-target ln -s /etc/init.d/oz-generate-ssh /etc/rc2.d/S40oz-generate-ssh
