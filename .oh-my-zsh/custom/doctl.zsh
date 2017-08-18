# Copyright 2017 The Doctl Authors All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


__doctl_bash_source() {
	alias shopt=':'
	alias _expand=_bash_expand
	alias _complete=_bash_comp
	emulate -L sh
	setopt kshglob noshglob braceexpand

	source "$@"
}

__doctl_type() {
	# -t is not supported by zsh
	if [ "$1" == "-t" ]; then
		shift

		# fake Bash 4 to disable "complete -o nospace". Instead
		# "compopt +-o nospace" is used in the code to toggle trailing
		# spaces. We don't support that, but leave trailing spaces on
		# all the time
		if [ "$1" = "__doctl_compopt" ]; then
			echo builtin
			return 0
		fi
	fi
	type "$@"
}

__doctl_compgen() {
	local completions w
	completions=( $(compgen "$@") ) || return $?

	# filter by given word as prefix
	while [[ "$1" = -* && "$1" != -- ]]; do
		shift
		shift
	done
	if [[ "$1" == -- ]]; then
		shift
	fi
	for w in "${completions[@]}"; do
		if [[ "${w}" = "$1"* ]]; then
			echo "${w}"
		fi
	done
}

__doctl_compopt() {
	true # don't do anything. Not supported by bashcompinit in zsh
}

__doctl_declare() {
	if [ "$1" == "-F" ]; then
		whence -w "$@"
	else
		builtin declare "$@"
	fi
}

__doctl_ltrim_colon_completions()
{
	if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
		# Remove colon-word prefix from COMPREPLY items
		local colon_word=${1%${1##*:}}
		local i=${#COMPREPLY[*]}
		while [[ $((--i)) -ge 0 ]]; do
			COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"}
		done
	fi
}

__doctl_get_comp_words_by_ref() {
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[${COMP_CWORD}-1]}"
	words=("${COMP_WORDS[@]}")
	cword=("${COMP_CWORD[@]}")
}

__doctl_filedir() {
	local RET OLD_IFS w qw

	__debug "_filedir $@ cur=$cur"
	if [[ "$1" = \~* ]]; then
		# somehow does not work. Maybe, zsh does not call this at all
		eval echo "$1"
		return 0
	fi

	OLD_IFS="$IFS"
	IFS=$'\n'
	if [ "$1" = "-d" ]; then
		shift
		RET=( $(compgen -d) )
	else
		RET=( $(compgen -f) )
	fi
	IFS="$OLD_IFS"

	IFS="," __debug "RET=${RET[@]} len=${#RET[@]}"

	for w in ${RET[@]}; do
		if [[ ! "${w}" = "${cur}"* ]]; then
			continue
		fi
		if eval "[[ \"\${w}\" = *.$1 || -d \"\${w}\" ]]"; then
			qw="$(__doctl_quote "${w}")"
			if [ -d "${w}" ]; then
				COMPREPLY+=("${qw}/")
			else
				COMPREPLY+=("${qw}")
			fi
		fi
	done
}

__doctl_quote() {
    if [[ $1 == \'* || $1 == \"* ]]; then
        # Leave out first character
        printf %q "${1:1}"
    else
    	printf %q "$1"
    fi
}

autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# use word boundary patterns for BSD or GNU sed
LWORD='[[:<:]]'
RWORD='[[:>:]]'
if sed --help 2>&1 | grep -q GNU; then
	LWORD='\<'
	RWORD='\>'
fi

__doctl_convert_bash_to_zsh() {
	sed \
	-e 's/declare -F/whence -w/' \
	-e 's/local \([a-zA-Z0-9_]*\)=/local \1; \1=/' \
	-e 's/flags+=("\(--.*\)=")/flags+=("\1"); two_word_flags+=("\1")/' \
	-e 's/must_have_one_flag+=("\(--.*\)=")/must_have_one_flag+=("\1")/' \
	-e "s/${LWORD}_filedir${RWORD}/__doctl_filedir/g" \
	-e "s/${LWORD}_get_comp_words_by_ref${RWORD}/__doctl_get_comp_words_by_ref/g" \
	-e "s/${LWORD}__ltrim_colon_completions${RWORD}/__doctl_ltrim_colon_completions/g" \
	-e "s/${LWORD}compgen${RWORD}/__doctl_compgen/g" \
	-e "s/${LWORD}compopt${RWORD}/__doctl_compopt/g" \
	-e "s/${LWORD}declare${RWORD}/__doctl_declare/g" \
	-e "s/\\\$(type${RWORD}/\$(__doctl_type/g" \
	<<'BASH_COMPLETION_EOF'
# bash completion for doctl                                -*- shell-script -*-

__debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__my_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__handle_reply()
{
    __debug "${FUNCNAME[0]}"
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            COMPREPLY=( $(compgen -W "${allflags[*]}" -- "$cur") )
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%%=*}"
                __index_of_word "${flag}" "${flags_with_completion[@]}"
                if [[ ${index} -ge 0 ]]; then
                    COMPREPLY=()
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zfs completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions=("${must_have_one_flag[@]}")
    elif [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    else
        completions=("${commands[@]}")
    fi
    COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        COMPREPLY=( $(compgen -W "${noun_aliases[*]}" -- "$cur") )
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        declare -F __custom_func >/dev/null && __custom_func
    fi

    __ltrim_colon_completions "$cur"
}

# The arguments should be in the form "ext1|ext2|extn"
__handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1
}

__handle_flag()
{
    __debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # keep flag value with flagname as flaghash
    if [ -n "${flagvalue}" ] ; then
        flaghash[${flagname}]=${flagvalue}
    elif [ -n "${words[ $((c+1)) ]}" ] ; then
        flaghash[${flagname}]=${words[ $((c+1)) ]}
    else
        flaghash[${flagname}]="true" # pad "true" for bool flag
    fi

    # skip the argument to a two word flag
    if __contains_word "${words[c]}" "${two_word_flags[@]}"; then
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__handle_noun()
{
    __debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__handle_command()
{
    __debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_$(basename "${words[c]//:/__}")"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F $next_command >/dev/null && $next_command
}

__handle_word()
{
    if [[ $c -ge $cword ]]; then
        __handle_reply
        return
    fi
    __debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __handle_flag
    elif __contains_word "${words[c]}" "${commands[@]}"; then
        __handle_command
    elif [[ $c -eq 0 ]] && __contains_word "$(basename "${words[c]}")" "${commands[@]}"; then
        __handle_command
    else
        __handle_noun
    fi
    __handle_word
}

_doctl_account_get()
{
    last_command="doctl_account_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_account_ratelimit()
{
    last_command="doctl_account_ratelimit"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_account()
{
    last_command="doctl_account"
    commands=()
    commands+=("get")
    commands+=("ratelimit")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_auth_init()
{
    last_command="doctl_auth_init"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_auth()
{
    last_command="doctl_auth"
    commands=()
    commands+=("init")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_completion_bash()
{
    last_command="doctl_completion_bash"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_completion_zsh()
{
    last_command="doctl_completion_zsh"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_completion()
{
    last_command="doctl_completion"
    commands=()
    commands+=("bash")
    commands+=("zsh")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_action_get()
{
    last_command="doctl_compute_action_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_action_list()
{
    last_command="doctl_compute_action_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--action-type=")
    flags+=("--after=")
    flags+=("--before=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--resource-type=")
    flags+=("--status=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_action_wait()
{
    last_command="doctl_compute_action_wait"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--poll-timeout=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_action()
{
    last_command="doctl_compute_action"
    commands=()
    commands+=("get")
    commands+=("list")
    commands+=("wait")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_certificate_get()
{
    last_command="doctl_compute_certificate_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_certificate_create()
{
    last_command="doctl_compute_certificate_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--certificate-chain-path=")
    flags+=("--leaf-certificate-path=")
    flags+=("--name=")
    flags+=("--private-key-path=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_certificate_list()
{
    last_command="doctl_compute_certificate_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_certificate_delete()
{
    last_command="doctl_compute_certificate_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_certificate()
{
    last_command="doctl_compute_certificate"
    commands=()
    commands+=("get")
    commands+=("create")
    commands+=("list")
    commands+=("delete")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_get()
{
    last_command="doctl_compute_droplet-action_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--action-id=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_disable-backups()
{
    last_command="doctl_compute_droplet-action_disable-backups"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_reboot()
{
    last_command="doctl_compute_droplet-action_reboot"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_power-cycle()
{
    last_command="doctl_compute_droplet-action_power-cycle"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_shutdown()
{
    last_command="doctl_compute_droplet-action_shutdown"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_power-off()
{
    last_command="doctl_compute_droplet-action_power-off"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_power-on()
{
    last_command="doctl_compute_droplet-action_power-on"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_password-reset()
{
    last_command="doctl_compute_droplet-action_password-reset"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_enable-ipv6()
{
    last_command="doctl_compute_droplet-action_enable-ipv6"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_enable-private-networking()
{
    last_command="doctl_compute_droplet-action_enable-private-networking"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_upgrade()
{
    last_command="doctl_compute_droplet-action_upgrade"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_restore()
{
    last_command="doctl_compute_droplet-action_restore"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--image-id=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_resize()
{
    last_command="doctl_compute_droplet-action_resize"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--resize-disk")
    flags+=("--size=")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_rebuild()
{
    last_command="doctl_compute_droplet-action_rebuild"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--image=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_rename()
{
    last_command="doctl_compute_droplet-action_rename"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-name=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_change-kernel()
{
    last_command="doctl_compute_droplet-action_change-kernel"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--kernel-id=")
    flags+=("--no-header")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action_snapshot()
{
    last_command="doctl_compute_droplet-action_snapshot"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--snapshot-name=")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet-action()
{
    last_command="doctl_compute_droplet-action"
    commands=()
    commands+=("get")
    commands+=("disable-backups")
    commands+=("reboot")
    commands+=("power-cycle")
    commands+=("shutdown")
    commands+=("power-off")
    commands+=("power-on")
    commands+=("password-reset")
    commands+=("enable-ipv6")
    commands+=("enable-private-networking")
    commands+=("upgrade")
    commands+=("restore")
    commands+=("resize")
    commands+=("rebuild")
    commands+=("rename")
    commands+=("change-kernel")
    commands+=("snapshot")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_actions()
{
    last_command="doctl_compute_droplet_actions"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_backups()
{
    last_command="doctl_compute_droplet_backups"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_create()
{
    last_command="doctl_compute_droplet_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--enable-backups")
    flags+=("--enable-ipv6")
    flags+=("--enable-monitoring")
    flags+=("--enable-private-networking")
    flags+=("--format=")
    flags+=("--image=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--size=")
    flags+=("--ssh-keys=")
    flags+=("--tag-name=")
    flags+=("--tag-names=")
    flags+=("--user-data=")
    flags+=("--user-data-file=")
    flags+=("--volumes=")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_delete()
{
    last_command="doctl_compute_droplet_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_get()
{
    last_command="doctl_compute_droplet_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--template=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_kernels()
{
    last_command="doctl_compute_droplet_kernels"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_list()
{
    last_command="doctl_compute_droplet_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--tag-name=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_neighbors()
{
    last_command="doctl_compute_droplet_neighbors"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_snapshots()
{
    last_command="doctl_compute_droplet_snapshots"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_tag()
{
    last_command="doctl_compute_droplet_tag"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--tag-name=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet_untag()
{
    last_command="doctl_compute_droplet_untag"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--tag-name=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_droplet()
{
    last_command="doctl_compute_droplet"
    commands=()
    commands+=("actions")
    commands+=("backups")
    commands+=("create")
    commands+=("delete")
    commands+=("get")
    commands+=("kernels")
    commands+=("list")
    commands+=("neighbors")
    commands+=("snapshots")
    commands+=("tag")
    commands+=("untag")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_create()
{
    last_command="doctl_compute_domain_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--ip-address=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_list()
{
    last_command="doctl_compute_domain_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_get()
{
    last_command="doctl_compute_domain_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_delete()
{
    last_command="doctl_compute_domain_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_records_list()
{
    last_command="doctl_compute_domain_records_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--domain-name=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_records_create()
{
    last_command="doctl_compute_domain_records_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--record-data=")
    flags+=("--record-name=")
    flags+=("--record-port=")
    flags+=("--record-priority=")
    flags+=("--record-ttl=")
    flags+=("--record-type=")
    flags+=("--record-weight=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_records_delete()
{
    last_command="doctl_compute_domain_records_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_records_update()
{
    last_command="doctl_compute_domain_records_update"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--record-data=")
    flags+=("--record-id=")
    flags+=("--record-name=")
    flags+=("--record-port=")
    flags+=("--record-priority=")
    flags+=("--record-ttl=")
    flags+=("--record-type=")
    flags+=("--record-weight=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain_records()
{
    last_command="doctl_compute_domain_records"
    commands=()
    commands+=("list")
    commands+=("create")
    commands+=("delete")
    commands+=("update")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_domain()
{
    last_command="doctl_compute_domain"
    commands=()
    commands+=("create")
    commands+=("list")
    commands+=("get")
    commands+=("delete")
    commands+=("records")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_get()
{
    last_command="doctl_compute_firewall_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_create()
{
    last_command="doctl_compute_firewall_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-ids=")
    flags+=("--inbound-rules=")
    flags+=("--name=")
    flags+=("--outbound-rules=")
    flags+=("--tag-names=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_update()
{
    last_command="doctl_compute_firewall_update"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-ids=")
    flags+=("--inbound-rules=")
    flags+=("--name=")
    flags+=("--outbound-rules=")
    flags+=("--tag-names=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_list()
{
    last_command="doctl_compute_firewall_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_list-by-droplet()
{
    last_command="doctl_compute_firewall_list-by-droplet"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_delete()
{
    last_command="doctl_compute_firewall_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_add-droplets()
{
    last_command="doctl_compute_firewall_add-droplets"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-ids=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_remove-droplets()
{
    last_command="doctl_compute_firewall_remove-droplets"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-ids=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_add-tags()
{
    last_command="doctl_compute_firewall_add-tags"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--tag-names=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_remove-tags()
{
    last_command="doctl_compute_firewall_remove-tags"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--tag-names=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_add-rules()
{
    last_command="doctl_compute_firewall_add-rules"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--inbound-rules=")
    flags+=("--outbound-rules=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall_remove-rules()
{
    last_command="doctl_compute_firewall_remove-rules"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--inbound-rules=")
    flags+=("--outbound-rules=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_firewall()
{
    last_command="doctl_compute_firewall"
    commands=()
    commands+=("get")
    commands+=("create")
    commands+=("update")
    commands+=("list")
    commands+=("list-by-droplet")
    commands+=("delete")
    commands+=("add-droplets")
    commands+=("remove-droplets")
    commands+=("add-tags")
    commands+=("remove-tags")
    commands+=("add-rules")
    commands+=("remove-rules")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip_create()
{
    last_command="doctl_compute_floating-ip_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-id=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip_get()
{
    last_command="doctl_compute_floating-ip_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip_delete()
{
    last_command="doctl_compute_floating-ip_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip_list()
{
    last_command="doctl_compute_floating-ip_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip()
{
    last_command="doctl_compute_floating-ip"
    commands=()
    commands+=("create")
    commands+=("get")
    commands+=("delete")
    commands+=("list")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip-action_get()
{
    last_command="doctl_compute_floating-ip-action_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip-action_assign()
{
    last_command="doctl_compute_floating-ip-action_assign"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip-action_unassign()
{
    last_command="doctl_compute_floating-ip-action_unassign"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_floating-ip-action()
{
    last_command="doctl_compute_floating-ip-action"
    commands=()
    commands+=("get")
    commands+=("assign")
    commands+=("unassign")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_list()
{
    last_command="doctl_compute_image_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--public")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_list-distribution()
{
    last_command="doctl_compute_image_list-distribution"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--public")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_list-application()
{
    last_command="doctl_compute_image_list-application"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--public")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_list-user()
{
    last_command="doctl_compute_image_list-user"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--public")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_get()
{
    last_command="doctl_compute_image_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_update()
{
    last_command="doctl_compute_image_update"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--image-name=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image_delete()
{
    last_command="doctl_compute_image_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image()
{
    last_command="doctl_compute_image"
    commands=()
    commands+=("list")
    commands+=("list-distribution")
    commands+=("list-application")
    commands+=("list-user")
    commands+=("get")
    commands+=("update")
    commands+=("delete")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image-action_get()
{
    last_command="doctl_compute_image-action_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--action-id=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image-action_transfer()
{
    last_command="doctl_compute_image-action_transfer"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--wait")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_image-action()
{
    last_command="doctl_compute_image-action"
    commands=()
    commands+=("get")
    commands+=("transfer")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_get()
{
    last_command="doctl_compute_load-balancer_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_create()
{
    last_command="doctl_compute_load-balancer_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--algorithm=")
    flags+=("--droplet-ids=")
    flags+=("--forwarding-rules=")
    flags+=("--health-check=")
    flags+=("--name=")
    flags+=("--redirect-http-to-https")
    flags+=("--region=")
    flags+=("--sticky-sessions=")
    flags+=("--tag-name=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_update()
{
    last_command="doctl_compute_load-balancer_update"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--algorithm=")
    flags+=("--droplet-ids=")
    flags+=("--forwarding-rules=")
    flags+=("--health-check=")
    flags+=("--name=")
    flags+=("--redirect-http-to-https")
    flags+=("--region=")
    flags+=("--sticky-sessions=")
    flags+=("--tag-name=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_list()
{
    last_command="doctl_compute_load-balancer_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_delete()
{
    last_command="doctl_compute_load-balancer_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_add-droplets()
{
    last_command="doctl_compute_load-balancer_add-droplets"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-ids=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_remove-droplets()
{
    last_command="doctl_compute_load-balancer_remove-droplets"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--droplet-ids=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_add-forwarding-rules()
{
    last_command="doctl_compute_load-balancer_add-forwarding-rules"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--forwarding-rules=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer_remove-forwarding-rules()
{
    last_command="doctl_compute_load-balancer_remove-forwarding-rules"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--forwarding-rules=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_load-balancer()
{
    last_command="doctl_compute_load-balancer"
    commands=()
    commands+=("get")
    commands+=("create")
    commands+=("update")
    commands+=("list")
    commands+=("delete")
    commands+=("add-droplets")
    commands+=("remove-droplets")
    commands+=("add-forwarding-rules")
    commands+=("remove-forwarding-rules")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_plugin_list()
{
    last_command="doctl_compute_plugin_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_plugin_run()
{
    last_command="doctl_compute_plugin_run"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_plugin()
{
    last_command="doctl_compute_plugin"
    commands=()
    commands+=("list")
    commands+=("run")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_region_list()
{
    last_command="doctl_compute_region_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_region()
{
    last_command="doctl_compute_region"
    commands=()
    commands+=("list")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_size_list()
{
    last_command="doctl_compute_size_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_size()
{
    last_command="doctl_compute_size"
    commands=()
    commands+=("list")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_snapshot_list()
{
    last_command="doctl_compute_snapshot_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--resource=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_snapshot_get()
{
    last_command="doctl_compute_snapshot_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_snapshot_delete()
{
    last_command="doctl_compute_snapshot_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_snapshot()
{
    last_command="doctl_compute_snapshot"
    commands=()
    commands+=("list")
    commands+=("get")
    commands+=("delete")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key_list()
{
    last_command="doctl_compute_ssh-key_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key_get()
{
    last_command="doctl_compute_ssh-key_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key_create()
{
    last_command="doctl_compute_ssh-key_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--public-key=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key_import()
{
    last_command="doctl_compute_ssh-key_import"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--public-key-file=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key_delete()
{
    last_command="doctl_compute_ssh-key_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key_update()
{
    last_command="doctl_compute_ssh-key_update"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--key-name=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh-key()
{
    last_command="doctl_compute_ssh-key"
    commands=()
    commands+=("list")
    commands+=("get")
    commands+=("create")
    commands+=("import")
    commands+=("delete")
    commands+=("update")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_tag_create()
{
    last_command="doctl_compute_tag_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_tag_get()
{
    last_command="doctl_compute_tag_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_tag_list()
{
    last_command="doctl_compute_tag_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_tag_delete()
{
    last_command="doctl_compute_tag_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_tag()
{
    last_command="doctl_compute_tag"
    commands=()
    commands+=("create")
    commands+=("get")
    commands+=("list")
    commands+=("delete")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume_list()
{
    last_command="doctl_compute_volume_list"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume_create()
{
    last_command="doctl_compute_volume_create"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--desc=")
    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--region=")
    flags+=("--size=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume_delete()
{
    last_command="doctl_compute_volume_delete"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume_get()
{
    last_command="doctl_compute_volume_get"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume_snapshot()
{
    last_command="doctl_compute_volume_snapshot"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--format=")
    flags+=("--no-header")
    flags+=("--snapshot-desc=")
    flags+=("--snapshot-name=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume()
{
    last_command="doctl_compute_volume"
    commands=()
    commands+=("list")
    commands+=("create")
    commands+=("delete")
    commands+=("get")
    commands+=("snapshot")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume-action_attach()
{
    last_command="doctl_compute_volume-action_attach"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume-action_detach()
{
    last_command="doctl_compute_volume-action_detach"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume-action_detach-by-droplet-id()
{
    last_command="doctl_compute_volume-action_detach-by-droplet-id"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume-action_resize()
{
    last_command="doctl_compute_volume-action_resize"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--region=")
    flags+=("--size=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_volume-action()
{
    last_command="doctl_compute_volume-action"
    commands=()
    commands+=("attach")
    commands+=("detach")
    commands+=("detach-by-droplet-id")
    commands+=("resize")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute_ssh()
{
    last_command="doctl_compute_ssh"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ssh-agent-forwarding")
    flags+=("--ssh-command=")
    flags+=("--ssh-key-path=")
    flags+=("--ssh-port=")
    flags+=("--ssh-private-ip")
    flags+=("--ssh-user=")
    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_compute()
{
    last_command="doctl_compute"
    commands=()
    commands+=("action")
    commands+=("certificate")
    commands+=("droplet-action")
    commands+=("droplet")
    commands+=("domain")
    commands+=("firewall")
    commands+=("floating-ip")
    commands+=("floating-ip-action")
    commands+=("image")
    commands+=("image-action")
    commands+=("load-balancer")
    commands+=("plugin")
    commands+=("region")
    commands+=("size")
    commands+=("snapshot")
    commands+=("ssh-key")
    commands+=("tag")
    commands+=("volume")
    commands+=("volume-action")
    commands+=("ssh")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl_version()
{
    last_command="doctl_version"
    commands=()

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_doctl()
{
    last_command="doctl"
    commands=()
    commands+=("account")
    commands+=("auth")
    commands+=("completion")
    commands+=("compute")
    commands+=("version")

    flags=()
    two_word_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--access-token=")
    two_word_flags+=("-t")
    flags+=("--config=")
    two_word_flags+=("-c")
    flags+=("--output=")
    two_word_flags+=("-o")
    flags+=("--trace")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_doctl()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __my_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("doctl")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_doctl doctl
else
    complete -o default -o nospace -F __start_doctl doctl
fi

# ex: ts=4 sw=4 et filetype=sh

BASH_COMPLETION_EOF
}

__doctl_bash_source <(__doctl_convert_bash_to_zsh)
	