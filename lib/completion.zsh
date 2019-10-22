# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'


# If you don't want compinit called here, place the line
# skip_global_compinit=1
# in your $ZDOTDIR/.zshenv or $ZDOTDIR/.zprofice
if [[ -z "$skip_global_compinit" ]]; then
  autoload -U compinit
  compinit
fi

############################################################################
#Added from zsh lovers
############################################################################
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
# Allowed no of errors in completion of commands gets bigger with length of what 
# I have typed..
zstyle -e ':completion:*:approximate:*' \
        max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Ignore completion for commands I don't have..
zstyle ':completion:*:functions' ignored-patterns '_*'

# Do not complete *.o, *.pyc, *.cmi, *.annot, *.cmo, *.cmt for vim
zstyle ':completion:*:*:v:*:*files' ignored-patterns '*?.aux' '*?.log' '*?.o' '*?.pyc' '*?.cmi' '*?.annot' '*?.cmo' '*?.cmt' '*?.aux' '*?.log' '*?.pdf'

zstyle ':completion:*:*:vim:*:*files' ignored-patterns '*?.aux' '*?.log' '*?.o' '*?.pyc' '*?.cmi' '*?.annot' '*?.cmo' '*?.cmt' '*?.aux' '*?.log' '*?.pdf'

zstyle ':completion:*:*:nvim:*:*files' ignored-patterns '*?.aux' '*?.log' '*?.o' '*?.pyc' '*?.cmi' '*?.annot' '*?.cmo' '*?.cmt' '*?.aux' '*?.log' '*?.pdf'

# Make zatura complete pdf files first and other files later only.
zstyle ':completion:*:*:z:*:*' file-patterns '*.pdf:pdf-files' '%p:all-files'

# Make mtex (makefile for tex autogeneration) complete tex files first
zstyle ':completion:*:*:mtex:*:*' file-patterns '*.tex:tex-files' '%p:all-files'


# Ignore same filename again when "removing" or "killing", only need single
# autocompletion for this
zstyle ':completion:*:(rm|kill|diff):*' ignore-line yes


#setopt complete_aliases


compdef '_files -g "*.gz *.tgz *.bz2 *.tbz *.zip *.rar *.tar *.lha"' extract_archive

function zle-line-init zle-keymap-select {
    RPS1="${${KEYMAP/vicmd/-- NORMAL --}/(main|viins)/-- INSERT --}"
    RPS2=$RPS1
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

compdef cs=cd
compdef _ins ins="apt-get install"
compdef _upd upd="sudo apt-get update"
compdef _upg upg="sudo apt-get upgrade"
compdef _cache-search cache-search="sudo apt-cache search"

# fixme - the load process here seems a bit bizarre
#zmodload -i zsh/complist

#WORDCHARS=''

#unsetopt menu_complete   # do not autoselect the first completion entry
#unsetopt flowcontrol
#setopt auto_menu         # show completion menu on successive tab press
#setopt complete_in_word
#setopt always_to_end

## should this be in keybindings?
#bindkey -M menuselect '^o' accept-and-infer-next-history
#zstyle ':completion:*:*:*:*:*' menu select

## case insensitive (all), partial-word and substring completion
#if [[ "$CASE_SENSITIVE" = true ]]; then
#  zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
#else
#  if [[ "$HYPHEN_INSENSITIVE" = true ]]; then
#    zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
#  else
#    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
#  fi
#fi
#unset CASE_SENSITIVE HYPHEN_INSENSITIVE

## Complete . and .. special directories
#zstyle ':completion:*' special-dirs true

#zstyle ':completion:*' list-colors ''
#zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

#if [[ "$OSTYPE" = solaris* ]]; then
#  zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm"
#else
#  zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
#fi

## disable named-directories autocompletion
#zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

## Use caching so that commands like apt and dpkg complete are useable
#zstyle ':completion::complete:*' use-cache 1
#zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR

## Don't complete uninteresting users
#zstyle ':completion:*:*:*:users' ignored-patterns \
#        adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
#        clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
#        gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
#        ldap lp mail mailman mailnull man messagebus  mldonkey mysql nagios \
#        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
#        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
#        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
#        usbmux uucp vcsa wwwrun xfs '_*'

## ... unless we really want to.
#zstyle '*' single-ignored show

if [[ $COMPLETION_WAITING_DOTS = true ]]; then
  expand-or-complete-with-dots() {
    # toggle line-wrapping off and back on again
    [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti rmam
    print -Pn "%{%F{red}......%f%}"
    [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti smam

    zle expand-or-complete
    zle redisplay
  }
  zle -N expand-or-complete-with-dots
  bindkey "^I" expand-or-complete-with-dots
fi

compdef cs=cd
compdef _ins ins="apt-get install"
compdef _upd upd="sudo apt-get update"
compdef _upg upg="sudo apt-get upgrade"
compdef _cache-search cache-search="sudo apt-cache search"
