#!/bin/bash
#run as sudo

git rev-parse HEAD > git_status.log
git status >> git_status.log

mkdir -p /usr/local/libvirt
rm /usr/local/libvirt/*
cp scripts/* /usr/local/libvirt/
chmod 755 /usr/local/libvirt/*
chown root:root /usr/local/libvirt/*

rm git_status.log