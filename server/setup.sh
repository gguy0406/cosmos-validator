#!/bin/bash
set -e

# Config ssh service, disable password login
echoc "Config ssh service, disable password login"
read -p "Input ssh port (default to 22 if empty): " sshPort

SSH_PORT=${sshPort:-22}
SSH_CONFIG=/etc/ssh/sshd_config

sudo sed -i -E "s/^#?PasswordAuthentication .*/PasswordAuthentication no/" $SSH_CONFIG
sudo sed -i -E "s/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/" $SSH_CONFIG
sudo sed -i -E "s/^#?PermitRootLogin .*/PermitRootLogin no/" $SSH_CONFIG
sudo sed -i -E "s/^#?Port .*/Port $SSH_PORT/" $SSH_CONFIG
sudo sed -i -E "s/^#?AddressFamily .*/AddressFamily inet/" $SSH_CONFIG
sudo sed -i -E "s/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/" $SSH_CONFIG
echo -ne "\e[32m"
sed -nE '/^#?PasswordAuthentication/p' $SSH_CONFIG
sed -nE '/^#?PermitEmptyPasswords/p' $SSH_CONFIG
sed -nE '/^#?PermitRootLogin/p' $SSH_CONFIG
sed -nE '/^#?Port/p' $SSH_CONFIG
sed -nE '/^#?AddressFamily/p' $SSH_CONFIG
sed -nE '/^#?PubkeyAuthentication/p' $SSH_CONFIG
echo -ne "\e[0m"
sudo systemctl restart ssh

# Config firewall
echoc "Configure firewall"
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow proto tcp to 0.0.0.0/0 port $SSH_PORT
sudo ufw allow proto tcp to 0.0.0.0/0 port 26656
sudo sed -i "/# ok icmp codes for INPUT/a -A ufw-before-input -p icmp --icmp-type echo-request -j DROP" /etc/ufw/before.rules
echo -ne "\e[32m"
sudo sed -n '/*echo-requrest -j DROP/p' /etc/ufw/before.rules
echo -ne "\e[0m"
yes | sudo ufw enable
sudo ufw status

# Set journalctl limit
echoc "Set journalctl limit"
sudo journalctl --vacuum-size=1G --vacuum-time=7days

# Import gpg public key
echoc "Import gpg public key"
bash -c "curl --fail-with-body -o ~/minds/public.gpg $GH_URL_OPTION/server/public.gpg"
gpg --import ~/minds/public.gpg
