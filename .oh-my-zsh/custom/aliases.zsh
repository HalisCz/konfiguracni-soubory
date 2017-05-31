
# ------------------OSOBNÍ ALIASY-----------------------
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
export GREP_COLOR="1;34"	# grep zvyraznuje modrou barvou

# ls aliases
alias ll='ls -hAlF' # human readable all list Folders highlight
alias la='ls -A'	# ls -a bez . a ..
alias l='ls -CF'	# sloupce

# ostatní
alias ssh="TERM=xterm ssh"	# řeší neznalost remote-hostů rxvt-unicode
alias tree="tree --dirsfirst"
alias locate="locate -i"    # nerozlišuje velikost písmen
alias redshifting="gtk-redshift -l 50:15"

# rozbalovací alias
un() { 
 for EXTRACT_FILE in $*; do
  if [ -f "$EXTRACT_FILE" ] ; then 
   FT1=$(file -bi "$EXTRACT_FILE" | grep -Eo '[[:alnum:]_-]+/[[:alnum:]_-]+')
   case $FT1 in 
    "application/x-bzip2") tar xvjf "$EXTRACT_FILE" || bunzip2 "$EXTRACT_FILE" ;; 
    "application/x-gzip") tar xvzf "$EXTRACT_FILE" || gunzip "$EXTRACT_FILE" ;; 
    "application/x-rar") rar x "$EXTRACT_FILE" || unrar x "$EXTRACT_FILE" ;; 
    "application/x-arj") arj x "$EXTRACT_FILE" || 7z x "$EXTRACT_FILE" ;; 
    "application/x-lha") lha x "$EXTRACT_FILE" || 7z x "$EXTRACT_FILE" ;; 
    "application/x-cpio") cpio -i "$EXTRACT_FILE" ;; 
    "application/x-tar, POSIX (GNU)") tar xvf "$EXTRACT_FILE" || gunzip "$EXTRACT_FILE" ;; 
    "application/x-tar") tar xvf "$EXTRACT_FILE" || gunzip "$EXTRACT_FILE" ;; 
    "application/x-zip") unzip "$EXTRACT_FILE" ;; 
    "application/zip") unzip "$EXTRACT_FILE" ;; 
    "application/octet-stream") unlzma "$EXTRACT_FILE" || 7z x "$EXTRACT_FILE" || uncompress "$EXTRACT_FILE" ;; 
    *) echo "'$EXTRACT_FILE' ($FT1) cannot be extracted via e() bash function" ;; 
   esac 
  else 
   echo "'$EXTRACT_FILE' is not a valid file" 
  fi 
 done
}

# síťové aliasy
alias pingg="ping -c 3 www.google.com"
alias wget="wget -c"           # wget navazuje prerusene stahovani

# vim
alias vim="vimx" # vim na fedoře není kompilovaný s podporou clipboardu