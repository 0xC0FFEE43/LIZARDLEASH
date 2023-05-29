#!/usr/bin/env bash

#
# Basic hardening script for REL derivatives such as Rocky Linux and AlmaLinux
# Config was tested on a fresh install of AlmaLinux
#

text() {
	tput setaf 2; echo "[*] $1"; tput sgr0 # sets terminal color to green and then resets the terminal attributes once done
}

chk_root() {
	if [ "$(id -u)" -eq 0 ]; then
		 "This script needs to be ran as root."
		exit
	fi
	sudo -k
	sudo true
}

sys_up() {
sudo dnf update -y 
}

fw_cfg() {
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=ssh # Adding port 22 as allowed on the firewall
sudo firewall-cmd --set-default-zone=drop # Good tradecraft to drop all IB connections and allow OB connections open ports as needed  via firewalld 
sudo firewall-cmd --reload # Reloads the service
}

dis_srv() {
sudo systemctl disable avahi-daemon.service # Disabling as per my use case this service essentially acts as a service discovery
sudo systemctl disable bluetooth.service # Servers don't need BT enabled
sudo systemctl disable cups.service # Printer is not needed on this server
sudo systemctl disable cups-browsed.service # See above
sudo systemctl disable nfs.service # Don't need nfs
sudo systemctl disable rpcbind.service  # Don't need RPC
sudo systemctl disable rpcbind.socket # see above
}

sys_ctl() {
echo 'kernel.dmesg_restrict=1' | sudo tee -a /etc/sysctl.conf > /dev/null # restrict dmesg to root users
echo 'kernel.kptr_restrict=1'| sudo tee -a /etc/sysctl.conf > /dev/null  # restricts exposed kernel pointer addresses part of STIG
echo 'kernel.ctrl-alt-del=0' | sudo tee -a /etc/sysctl.conf > /dev/null  # if ctrl+alt+del is hit a graceful restart is initiated 
echo 'net.ipv4.conf.all.log_martians=1' | sudo tee -a /etc/sysctl.conf > /dev/null  # system must log Martian packets part of STIG
echo 'net.ipv4.conf.all.rp_filter=1' | sudo tee -a /etc/sysctl.conf > /dev/null  # prevents IP spoofing
echo 'net.ipv4.conf.default.log_martians=1' | sudo tee -a /etc/sysctl.conf > /dev/null # system must log Martian packets part of STIG
echo 'net.ipv4.tcp_rfc1337 = 1' | sudo tee -a /etc/sysctl.conf > /dev/null  # drop RST packets for sockets in the time-wait state
echo 'net.ipv4.icmp__ignore_all = 1' | sudo tee -a /etc/sysctl.conf > /dev/null  # disable ping
echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf > /dev/null  # disable ipv6 
echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf > /dev/null  # part of above rule 
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf > /dev/null  # part of above rule 
echo 'kernel.unprivileged_bpf_disabled=1' | sudo tee -a /etc/sysctl.conf > /dev/null  # disable unprivileged eBPF
echo 'net.core.bpf_jit_harden=2' | sudo tee -a /etc/sysctl.conf > /dev/null  # hardens BPF JIT compiler for all users 
echo 'kernel.yama.ptrace_scope=2' | sudo tee -a /etc/sysctl.conf > /dev/null  # admin only can attach ptraces
echo 'kernel.sysrq=0' | sudo tee -a /etc/sysctl.conf > /dev/null  # disables magic stsrq key

}

sys_disable_ctrl(){
sudo systemctl disable ctrl-alt-del.target
sudo systemctl mask ctrl-alt-del.target
sudo systemctl daemon-reload 
}

remove_sw() {
sudo dnf remove rsh-server # as per RHEL STIG
sudo dnf remove tftp-server # as per RHEL STIG
sudo dnf remove krb5-workstation # as per RHEL STIG
}

add_sw(){
sudo dnf install policycoreutils # as per STIG as well as in aid in SELINUX configuration
}

main() 
{
chk_root
text "Hardening sysctl values"
sys_ctl
#fw_cfg
#dis_srv
fw_cfg
dis_srv
sys_disable_ctrl
remove_sw
add_sw
}
main
