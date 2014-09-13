# completion
	source /etc/profile.d/bash-completion.sh

# aliasy
	if [ -f ~/.aliases ]; then
		source ~/.aliases
	fi

# git status
	if [ -f ~/.git-prompt.sh ]; then
		source ~/.git-prompt.sh
		PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w\[\e[01;32m\]$(__git_ps1 " (%s)")\[\e[m\] \$\[\033[00m\] '
	else
		PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \W \$\[\033[00m\] '
	fi

# historie
	export HISTSIZE=1000000
	export HISTTIMEFORMAT='%F %T '
	#export HISTIGNORE=""
	export HISTCONTROL="ignorespace:ignoredups:erasedups"
	export HISTFILESIZE=20000
	export PROMPT_COMMAND="$PROMPT_COMMAND ; history -a;history -r"	# okamžitě zapisuje a znovunačítá historii

	shopt -s autocd	# autocd
	shopt -s hostcomplete # doplňuje hostnames
	# do not overwrite files when redirecting output
	set -o noclobber

# fortune
	if [ "$PS1" ]; then
		echo -e "\e[33m"
		/usr/bin/fortune -s
		echo -e "\e[39m"
	fi
