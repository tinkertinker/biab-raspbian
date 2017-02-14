alias ls='ls --color=auto'

export HISTCONTROL=ignoredups
export HISTCONTROL=ignoreboth
export CLICOLOR=1
export EDITOR=vi

if [ -f /etc/bash_completion ]; then
. /etc/bash_completion
fi

export PS1="\[\e[32m\]\u\[\e[m\]\[\e[33m\]@\[\e[m\]\[\e[32m\]\h\[\e[m\]:\[\e[36m\]\w\[\e[m\] "
export WP_CORE_DIR=/opt/wordpress

. ~/.wpcli.bash
