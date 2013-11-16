# completion
	source /etc/profile.d/bash-completion.sh

# aliasy
	if [ -f ~/.aliases ]; then
		source ~/.aliases
	fi

# historie
	export HISTSIZE=100000
	export HISTTIMEFORMAT='%F %T '
	#export HISTIGNORE=""
	export HISTCONTROL="ignorespace:ignoredups:erasedups"
	export HISTFILESIZE=20000
	export PROMPT_COMMAND='history -a;history -r'	# okamžitě zapisuje a znovunačítá historii

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
