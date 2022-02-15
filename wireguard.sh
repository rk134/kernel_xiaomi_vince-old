#!/usr/bin/env bash
DIR=$(pwd)
echo -ne "\033[1;36m Provide latest version of wireguard: \033[0m"
read -r ver
path="/workspace/buildbot/kernel"
if [ -d "${path}/drivers/net/wireguard" ]; then
	rm -rf ${path}/drivers/net/wireguard
	cd ${path} || exit 1
	git add drivers/net/wireguard
	git commit -S -s -m "drivers/net: removed wireguard from drivers/net"
fi
wget https://git.zx2c4.com/wireguard-linux-compat/snapshot/wireguard-linux-compat-"${ver}".zip
unzip wireguard-linux-compat-"${ver}".zip -d wireguard
cp -r wireguard/*/src/* "${path}"/net/wireguard
cd "${path}" || exit 1
git add net/wireguard/*
git commit -S -s -m "wireguard: Update to ${ver}"
cd "${DIR}" || exit 1
echo -e "\n\033[1;36m Done! Merged latest wireguard ${ver} \033[0m"