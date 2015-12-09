# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
[[ -f ~/.bashrc ]] && . ~/.bashrc

# fortune
echo -e "\e[33m"
/usr/bin/fortune -s
echo -e "\e[39m"
