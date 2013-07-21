# Shell functions
setenv() { export $1=$2 }	 # kompatibilita s csh

# Set prompts
###############################################################################
##								   PROMPT									 ##
###############################################################################
autoload -U promptinit compinit && promptinit && compinit

if [ $USER = root ]; then
		prompt adam2 cyan red red forground;
	else
		prompt adam2 blue cyan green forground;
	fi
###############################################################################
##								 END PROMPT									 ##
###############################################################################

# bindkey -v				 # editor jako vi
# bindkey -e				 # editor jako emacs
typeset -g -A key
bindkey '^?' backward-delete-char
bindkey '^[[7~' beginning-of-line
bindkey '^[[5~' up-line-or-history
bindkey '^[[3~' delete-char
bindkey '^[[8~' end-of-line
bindkey '^[[6~' down-line-or-history
bindkey '^[[A' up-line-or-search
bindkey '^[[D' backward-char
bindkey '^[[B' down-line-or-search
bindkey '^[[C' forward-char 
bindkey '^[[2~' overwrite-mode
bindkey ' ' magic-space		 # mezerník rozbaluje odkazy na historii
bindkey "\e[1~" beginning-of-line # Home
bindkey "\e[4~" end-of-line # End
bindkey "\e[5~" beginning-of-history # PageUp
bindkey "\e[6~" end-of-history # PageDown
bindkey "\e[2~" quoted-insert # Ins
bindkey "\e[3~" delete-char # Del
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "\e[Z" reverse-menu-complete # Shift+Tab
# for rxvt
bindkey "\e[7~" beginning-of-line # Home
bindkey "\e[8~" end-of-line # End
# for non RH/Debian xterm, can't hurt for RH/Debian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# for guake
bindkey "\eOF" end-of-line
bindkey "\eOH" beginning-of-line
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "\e[3~" delete-char # Del
bindkey '^R' history-incremental-search-backward


# OSOBNI ALIASY
# pripoji osobni aliasy pokud existuji
if [ -f ~/.aliases ]; then
	source ~/.aliases
fi

# Set OPTIONS
# nastavení historie
HISTSIZE=10000						# poèet øádkù
HISTFILE=~/.history					# soubor pro ukládání do historie
SAVEHIST=$HISTSIZE					# poèet øádkù po logoutu
setopt HISTIGNORESPACE			    # øádek zaèínající mezerou si nepamatuje
setopt HISTIGNOREALLDUPS			# vyhazuje z historie staré duplikáty
setopt APPENDHISTORY				# nepøepisuje historii
setopt EXTENDED_HISTORY             # dal¹í údaje jako timestamp atd.
setopt INC_APPEND_HISTORY           # pøidává do historie okam¾itì
setopt HIST_FIND_NO_DUPS            # nezobrazuje duplikáty pøi vyhledávání
setopt SHARE_HISTORY                # sdíli historii mezi terminály

setopt EXTENDED_GLOB				# roz¹íøené ¾olíkové znaky
setopt NO_CLOBBER					# ochrana pøi pøesmìrovávání výstupù
# setopt CORRECTALL					# opravy pøeklepù
setopt NO_BEEP						# nepípat pøi chybách
setopt AUTOCD						# /etc == cd /etc
setopt completealiases

# File completion
setopt autonamedirs alwaystoend nomenucomplete
setopt COMPLETE_ALIASES AUTO_NAME_DIRS AUTO_PARAM_SLASH AUTO_REMOVE_SLASH
setopt automenu autolist
setopt autoparamkeys listambiguous listbeep listpacked listtypes
zmodload -i zsh/complist			# obarví vypisované doplòování
autoload colors
#eval $(dircolors -b ~/.dir_colors)
eval $(dircolors -b)
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin # pøi sudo doplòuje jinak
zstyle ':completion:*' completer _oldlist _complete _match _prefix _list _approximate
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z} m:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'
zstyle ':completion:*' match-original both
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
zstyle ':completion:*' verbose yes
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' group-name ''
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
if [ $USER = root ]; then
    zstyle ':completion:*:*:kill:*:processes' command 'ps --forest -A -o pid,user,%cpu,cmd'
else
    zstyle ':completion:*:*:kill:*:processes' command 'ps fx -o pid,user,%cpu,cmd'
fi
zstyle ':completion:*:processes-names' command 'ps axho command'

case "$TERM" in
  # [skipping some esoteric terminal emulators...]

  screen|screen.rxvt)
     # Set a coloured prompt
     PS1=$'%{\e[00;32m%}%*%{\e[00;34m%}%2~ %# %{\e[00m%}'
     ;;
  rxvt|rxvt-unicode|xterm|xterm-color)
     # Set the title, and a coloured prompt containing some useful info
     PS1=$'%{\e]0;%-3~\a\e\[00;32m%}%*%{\e[00;30m%}!%! %{\e[00;34m%}%2~ %# %{\e[0m%}'
     ;;
esac

function preexec() {
  local a=${${1## *}[(w)1]}  # get the command
  local b=${a##*\/}   # get the command basename
  a="${b}${1#$a}"     # add back the parameters
  a=${a//\%/\%\%}     # escape print specials
  a=$(print -Pn "$a" | tr -d "\t\n\v\f\r")  # remove fancy whitespace
  a=${(V)a//\%/\%\%}  # escape non-visibles and print specials

  case "$TERM" in
    screen|screen.*)
      # See screen(1) "TITLES (naming windows)".
      # "\ek" and "\e\" are the delimiters for screen(1) window titles
      print -Pn "\ek%-3~ $a\e\\" # set screen title.  Fix vim: ".
      print -Pn "\e]2;%-3~ $a\a" # set xterm title, via screen "Operating System Command"
      ;;
    rxvt|rxvt-unicode|xterm|xterm-color|xterm-256color)
      print -Pn "\e]2;%m:%-3~ $a\a"
      ;;
  esac
}

function precmd() {
  case "$TERM" in
    screen|screen.rxvt)
      print -Pn "\ek%-3~\e\\" # set screen title
      print -Pn "\e]2;%-3~\a" # must (re)set xterm title
      ;;
  esac
  echo -ne '\a'		# audible on finished command
}

if [ $USER = halis ]; then
	eval `keychain --confirm --quiet --agents gpg --eval`
fi

# powerline
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [[ -r ~/.local/lib64/python3.2/site-packages/powerline/bindings/zsh/powerline.zsh ]]; then
    source ~/.local/lib64/python3.2/site-packages/powerline/bindings/zsh/powerline.zsh
fi
