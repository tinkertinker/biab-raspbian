echo '=============================================================================================='
echo `date +"%A, %e %B %Y, %r"`
echo `uname -srmo`
echo 'Memory: ' `cat /proc/meminfo | grep MemFree | awk {'print $2'}` 'kB (Free)' / `cat /proc/meminfo | grep MemTotal | awk {'print $2'}` 'kB (Total)'
echo 'IP Addresses:' `/sbin/ifconfig | /bin/grep "inet addr" | /usr/bin/cut -d ":" -f 2 | /usr/bin/cut -d " " -f 1`
echo '=============================================================================================='
echo ""

if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

source ~/.nvm/nvm.sh
