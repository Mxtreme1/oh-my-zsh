function zsh_stats() {
  fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n20
}

function uninstall_oh_my_zsh() {
  env ZSH=$ZSH sh $ZSH/tools/uninstall.sh
}

function upgrade_oh_my_zsh() {
  env ZSH=$ZSH sh $ZSH/tools/upgrade.sh
}

function take() {
  mkdir -p $@ && cd ${@:$#}
}

function open_command() {
  local open_cmd

  # define the open command
  case "$OSTYPE" in
    darwin*)  open_cmd='open' ;;
    cygwin*)  open_cmd='cygstart' ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open' || {
                open_cmd='cmd.exe /c start ""'
                [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
              } ;;
    msys*)    open_cmd='start ""' ;;
    *)        echo "Platform $OSTYPE not supported"
              return 1
              ;;
  esac

  ${=open_cmd} "$@" &>/dev/null
}

#
# Get the value of an alias.
#
# Arguments:
#    1. alias - The alias to get its value from
# STDOUT:
#    The value of alias $1 (if it has one).
# Return value:
#    0 if the alias was found,
#    1 if it does not exist
#
function alias_value() {
    (( $+aliases[$1] )) && echo $aliases[$1]
}

#
# Try to get the value of an alias,
# otherwise return the input.
#
# Arguments:
#    1. alias - The alias to get its value from
# STDOUT:
#    The value of alias $1, or $1 if there is no alias $1.
# Return value:
#    Always 0
#
function try_alias_value() {
    alias_value "$1" || echo "$1"
}

#
# Set variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The variable to set
#    2. val  - The default value
# Return value:
#    0 if the variable exists, 3 if it was set
#
function default() {
    (( $+parameters[$1] )) && return 0
    typeset -g "$1"="$2"   && return 3
}

#
# Set environment variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The env variable to set
#    2. val  - The default value
# Return value:
#    0 if the env variable exists, 3 if it was set
#
function env_default() {
    (( ${${(@f):-$(typeset +xg)}[(I)$1]} )) && return 0
    export "$1=$2" && return 3
}


# Required for $langinfo
zmodload zsh/langinfo

# URL-encode a string
#
# Encodes a string using RFC 2396 URL-encoding (%-escaped).
# See: https://www.ietf.org/rfc/rfc2396.txt
#
# By default, reserved characters and unreserved "mark" characters are
# not escaped by this function. This allows the common usage of passing
# an entire URL in, and encoding just special characters in it, with
# the expectation that reserved and mark characters are used appropriately.
# The -r and -m options turn on escaping of the reserved and mark characters,
# respectively, which allows arbitrary strings to be fully escaped for
# embedding inside URLs, where reserved characters might be misinterpreted.
#
# Prints the encoded string on stdout.
# Returns nonzero if encoding failed.
#
# Usage:
#  omz_urlencode [-r] [-m] [-P] <string>
#
#    -r causes reserved characters (;/?:@&=+$,) to be escaped
#
#    -m causes "mark" characters (_.!~*''()-) to be escaped
#
#    -P causes spaces to be encoded as '%20' instead of '+'
function omz_urlencode() {
  emulate -L zsh
  zparseopts -D -E -a opts r m P

  local in_str=$1
  local url_str=""
  local spaces_as_plus
  if [[ -z $opts[(r)-P] ]]; then spaces_as_plus=1; fi
  local str="$in_str"

  # URLs must use UTF-8 encoding; convert str to UTF-8 if required
  local encoding=$langinfo[CODESET]
  local safe_encodings
  safe_encodings=(UTF-8 utf8 US-ASCII)
  if [[ -z ${safe_encodings[(r)$encoding]} ]]; then
    str=$(echo -E "$str" | iconv -f $encoding -t UTF-8)
    if [[ $? != 0 ]]; then
      echo "Error converting string from $encoding to UTF-8" >&2
      return 1
    fi
  fi

  # Use LC_CTYPE=C to process text byte-by-byte
  local i byte ord LC_ALL=C
  export LC_ALL
  local reserved=';/?:@&=+$,'
  local mark='_.!~*''()-'
  local dont_escape="[A-Za-z0-9"
  if [[ -z $opts[(r)-r] ]]; then
    dont_escape+=$reserved
  fi
  # $mark must be last because of the "-"
  if [[ -z $opts[(r)-m] ]]; then
    dont_escape+=$mark
  fi
  dont_escape+="]"

  # Implemented to use a single printf call and avoid subshells in the loop,
  # for performance (primarily on Windows).
  local url_str=""
  for (( i = 1; i <= ${#str}; ++i )); do
    byte="$str[i]"
    if [[ "$byte" =~ "$dont_escape" ]]; then
      url_str+="$byte"
    else
      if [[ "$byte" == " " && -n $spaces_as_plus ]]; then
        url_str+="+"
      else
        ord=$(( [##16] #byte ))
        url_str+="%$ord"
      fi
    fi
  done
  echo -E "$url_str"
}

# URL-decode a string
#
# Decodes a RFC 2396 URL-encoded (%-escaped) string.
# This decodes the '+' and '%' escapes in the input string, and leaves
# other characters unchanged. Does not enforce that the input is a
# valid URL-encoded string. This is a convenience to allow callers to
# pass in a full URL or similar strings and decode them for human
# presentation.
#
# Outputs the encoded string on stdout.
# Returns nonzero if encoding failed.
#
# Usage:
#   omz_urldecode <urlstring>  - prints decoded string followed by a newline
function omz_urldecode {
  emulate -L zsh
  local encoded_url=$1

  # Work bytewise, since URLs escape UTF-8 octets
  local caller_encoding=$langinfo[CODESET]
  local LC_ALL=C
  export LC_ALL

  # Change + back to ' '
  local tmp=${encoded_url:gs/+/ /}
  # Protect other escapes to pass through the printf unchanged
  tmp=${tmp:gs/\\/\\\\/}
  # Handle %-escapes by turning them into `\xXX` printf escapes
  tmp=${tmp:gs/%/\\x/}
  local decoded
  eval "decoded=\$'$tmp'"

  # Now we have a UTF-8 encoded string in the variable. We need to re-encode
  # it if caller is in a non-UTF-8 locale.
  local safe_encodings
  safe_encodings=(UTF-8 utf8 US-ASCII)
  if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]; then
    decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding)
    if [[ $? != 0 ]]; then
      echo "Error converting string from UTF-8 to $caller_encoding" >&2
      return 1
    fi
  fi

  echo -E "$decoded"
}


# Self made stuff

# add to visudo                    {{{
visudo_add() {
    cmdname=`whereis -b "$@" | awk {'print $2'}`
    echo "ALL ALL = NOPASSWD:$cmdname" | sudo tee "$1"
}
#                                               }}}


# insert full pdf2 into pdf1                    {{{
insert_pdf_at_page() {
    if [ "$#" -lt 3 ]
    then
        echo "USAGE: insert_pdf_at_page BIG.pdf TOINSERT.pdf AT_PAGE [OUTFILE.pdf]"
    else
        if [ "$4" ]
        then
            output="$4"
        else
            output="output_merged.pdf"
        fi
        big_pdf="$1"
        small_pdf="$2"
        breakpoint=$(expr "$3" - 1)
        pdftk A="$1" B="$2" cat A1-"$breakpoint" B A"${3}"-end output "$output"
        echo "Wrote merged pdf to file '$output'."
    fi
}

#                                               }}}


# kill process by grepping for regex            {{{
killgrep () {
    python "$DOTFILES_REPOSITORY_PATH/killgrep/killgrep.py" "$@"
}
#                                               }}}


# grep in manpage for regex                     {{{
mangrep () {
    MANARG="$1"
    shift
    man "$MANARG" | grep "$@"
}
#                                               }}}


# SXIV                                  {{{
sxiv() {
    /usr/bin/sxiv "$@" &!
}
#                                               }}}


# CS: CD + LS                                   {{{
cs() {
    if ! [ "$1" ]
    then
        cd "$HOME" && ls
    else
        var=$(expr $# - 1)
        cd "${@: -1}" && ls --color=auto "${@:1:$var}"
    fi
}
#                                               }}}


# get current weather in given city             {{{
weather() {
    if [ "$1" ] 
    then
        curl wttr.in/$1
    else
        echo "Usage: weather CITY"
        exit(1)
    fi
}



#                                               }}}


# mp4 --> mp3                                   {{{
mp4tomp3() {
    ffmpeg -i "$1" -vn \
        -acodec libmp3lame -ac 2 -qscale:a 4 -ar 48000 "$2"
}



#                                               }}}


# build + install a new program (with configure arguments) {{{
# XXX Once my "builder" tool is sophisticated enough, it should supersede 
# this function in functionality; switch to using it instead then
build() {
    ./configure "$@" && make -j && sudo make -j install
}

#                                               }}}


# Fix broken zsh history file                   {{{
fix_zsh_history() {
    mv "$HOME/.zsh_history" "$HOME/.zsh_history_bad"
    strings "$HOME/.zsh_history_bad" > "$HOME/.zsh_history"
    fc -R "$HOME/.zsh_history"
}
#                                               }}}


# PI: Fast directory switching                  {{{

# Fast access to directories => replace csd,css,etc in the long run
# TODO: Generate/Allow/enable autocompletion for this pi command
function pi() { 
    cmd=$(grep $1 ~/.pi | head -1)
    if [ -z "$cmd" ]; then
        echo "$1 is not stored as pi-accessible directory yet!"
    fi
    shift
    if [ "$1" ]; then
        cd "$cmd" && cs "$@"
    else
        cs "$cmd"
    fi
}

function addpi() { 
    if [ "$#" = 0 ]; then
        # no arguments => add current path
        echo "$PWD" >> ~/.pi 
    else
        while [[ $# -gt 0 ]]; do
            # arguments = for each directory given as argument, add it 
            # to .pi file for fast access
            argpath="$PWD/$1"
            if [ -d "${argpath}" ]; then
                echo "$PWD/$1" >> ~/.pi
            fi
            shift
        done
    fi
}

function mvpi() {
    if [[ $# -lt 2 ]]; then
        echo "usage: $(basename $0) FILES TARGET"
        exit 1
    fi

    target_regexp="${@: -1}"
    target_location=$(grep "$target_regexp" ~/.pi | head -1)

    index=$(expr $# - 1)
    files="${@:1:$index}"

    if [ -z "$target_location" ]; then
        echo "$target_regexp is not stored as pi-accessible directory yet!"
        exit 1
    else
        mv "$files" "$target_location"
    fi
}

#                                               }}}


# Spawn Fortune Cookie                          {{{
 
small_fortune() { 
    string=""
    size=10000
    while [[ "$size" -ge 100 || $string != *"--"* ]]; do
        string=$(fortune people wisdom literature work)
        size=${#string}
    done
    echo "$string"
}

#                                               }}}


# Extract any archive                           {{{
 
# added from zshwiki: extract any archive
extract_archive () {
    local old_dirs current_dirs lower
    lower=${(L)1}
    old_dirs=( *(N/) )
    if [[ $lower == *.tar.gz || $lower == *.tgz ]]; then
        tar zxfv $1
    elif [[ $lower == *.gz ]]; then
        gunzip $1
    elif [[ $lower == *.tar.bz2 || $lower == *.tbz ]]; then
        bunzip2 -c $1 | tar xfv -
    elif [[ $lower == *.bz2 ]]; then
        bunzip2 $1
    elif [[ $lower == *.zip ]]; then
        unzip $1
    elif [[ $lower == *.rar ]]; then
        unrar e $1
    elif [[ $lower == *.tar ]]; then
        tar xfv $1
    elif [[ $lower == *.lha ]]; then
        lha e $1
    else
        print "Unknown archive type: $1"
        return 1
    fi
    # Change in to the newly created directory, and
    # list the directory contents, if there is one.
    current_dirs=( *(N/) )
    for i in {1..${#current_dirs}}; do
        if [[ $current_dirs[$i] != $old_dirs[$i] ]]; then
            cd $current_dirs[$i]
            ls
            break
        fi
    done
}

#                                               }}}


# Open program and close spawning terminal      {{{

# firefox web browser
f () {
   if  (($# >= 2)); then
        # If we have more than 2 arguments, some options were specified. 
        # Run firefox normally.
        exec /usr/bin/firefox "$@" & disown
    else
        PPPID=$$
        if [ "$1" ]; then
            # Exactly one argument! We were called with some url
            # => just open it and kill my nasty terminal.
            exec /usr/bin/firefox "$1" & disown
        else
            # No arguments => open empty instance
            exec /usr/bin/firefox & disown
        fi
        kill -s SIGKILL $PPPID
    fi
}
# vim
v () {
    random_string=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    /usr/bin/vim -p --servername "$random_string" "$@"
}
#                                               }}}


# zathura pdf viewer  {{{
z () {
    # the {...} stuff is for autocompletion...
    command zathura ${*:-*.pdf(om[1])} & disown
}

#                                               }}}


# Smart shutdown                                {{{

function sd() {
    # no argument = now
    if [ -z "$1" ]; then
        sudo shutdown -P now
    else
        # argument = treated as minutes
        sudo shutdown -P "$1"
    fi
}

#                                               }}}


#  Smart reboot {{{ # 
function re() {
    # no argument = now
    if [ -z "$1" ]; then
        sudo shutdown --reboot now
    else
        # argument = treated as minutes
        sudo shutdown --reboot "$1"
    fi
}
#  }}} Smart reboot # 


#  Make directory and move into it at the same time {{{ # 

function mkd() {
    mkdir -p "$@" && cd "$_"
}

#  }}} Make directory and move into it at the same time # 


#  Pack+Pipe file to ssh server {{{ # 

# pipe a given file (first argument) to a ssh server.
# example usage: pipe_ssh "test.txt" "ssh test@test.testtest.com"
function pipe_ssh() {
   if [[ $# -eq 0 ]]; then 
       echo "USAGE: pipe_ssh FILENAME ssh test@test.testtest.com"
   else
       tar zcf - "$1" | "${@:2}" 'tar zxf -'
   fi
}

#  }}} Pack+Pipe file to ssh server # 


#  Most Frequently Used Commands {{{ # 
most_used_commands() {
    if [[ "$1" = "--help" || "$1" = "-h" ]]; then
        echo "USAGE: most_used_commands [NUMBER_OF_COMMANDS=10]"
    else
        no="10"
        if [ "$1" ]; then
            no="$1"
        fi
        cat "$HOME/.zsh_history" | awk '{CMD[$1]++;count++;}END { for (a in CMD)print CMD[a]" "CMD[a]/count*100 "% "a;}' | grep -v ",/" | column -c3 -s " " -t | sort -nr | nl | head -n$no
    fi
}
#  }}} Most Frequently Used Commands # 

