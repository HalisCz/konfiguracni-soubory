# completion
	source /etc/profile.d/bash-completion.sh

# aliasy
	if [ -f ~/.aliases ]; then
		source ~/.aliases
	fi

# historie
	export HISTSIZE=10000
	export HISTTIMEFORMAT='%F %T '
	#export HISTIGNORE=""
	export HISTCONTROL="ignorespace:ignoredups:erasedups"
	export HISTFILESIZE=20000
	export PROMPT_COMMAND='history -a;history -r'	# okamžitě zapisuje a znovunačítá historii

	shopt -s autocd	# autocd
	shopt -s hostcomplete # doplňuje hostnames
	# do not overwrite files when redirecting output
	set -o noclobber


# keychain
	if [ $USER = halis ]; then
		eval `keychain --confirm --quiet --agents gpg --eval`
	fi

# powerline
##if [ -d "$HOME/.local/bin" ]; then
##	PATH="$HOME/.local/bin:$PATH"
##fi
##if [ -f ~/.local/lib64/python3.2/site-packages/powerline/bindings/bash/powerline.sh ]; then
##	source ~/.local/lib64/python3.2/site-packages/powerline/bindings/bash/powerline.sh
##fi
