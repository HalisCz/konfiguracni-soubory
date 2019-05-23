# aliasy
if [ -f ~/.aliases ]; then
	source ~/.aliases
fi

# git status
case $TERM in
	xterm*|rxvt*)
		TITLEBAR='\[\033]0;\u@\h:\w\007\]'
		;;
	*)
		TITLEBAR=''
		;;
esac
if [ -f ~/.git-prompt.sh ]; then
	source ~/.git-prompt.sh
	PS1='\[\e]0;\u@\h: \w\007\]\[\e[01;32m\]\u@\h\[\e[01;34m\] \W\[\e[01;32m\]$(__git_ps1 " (%s)")\[\e[0m\] \$\[\e[0m\a\] '
else
	PS1='\[\e]0;\u@\h: \w\007\]\[\e[01;32m\]\u@\h\[\e[01;34m\] \W\[\e[0m\] \$\[\e[0m\a\] '
fi

# historie
export HISTSIZE=1000000
export HISTTIMEFORMAT='%F %T '
#export HISTIGNORE=""
export HISTCONTROL="ignorespace:ignoredups:erasedups"
export HISTFILESIZE=20000
export PROMPT_COMMAND='history -a;history -r'	# okamžitě zapisuje a znovunačítá historii

shopt -s autocd	# autocd
shopt -s hostcomplete # doplňuje hostnames
# do not overwrite files when redirecting output
set -o noclobber

# MC barvy
export MC_SKIN=$HOME/.config/mc/solarized.ini

# Pokud je shell interaktivni
if [ -t 0 ]; then
	echo -e "\e[33m"
	/usr/bin/fortune -s
	echo -e "\e[39m"
fi
