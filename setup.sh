#!/bin/bash

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

# Ubuntu's short release version name: trusty, utopic, etc..
REL=$(lsb_release -cs)

# Ubuntu's version number: 14.04, 14.10, 15.04 etc.
VER=$(lsb_release -sr)


MSFPATH='/usr/local/share/metasploit-framework' # location of metapsploit installation
MSFRVERSION='2.1.6' # ruby version to install for metapsloit

# declares associative array
declare -A GIT

GIT=(
    ['git@github.com:dtrip/sqlmap.git']='/usr/local/share/sqlmap'
    ['git@github.com:dtrip/metasploit-framework']=$MSFPATH
    ['git@github.com:dtrip/commix.git']='/usr/local/share/commix'
    ['git@github.com:dtrip/websploit.git']='/usr/local/share/websploit'
    ['git@github.com:dtrip/vim.git']='~/.vim'
    ['git@github.com:dtrip/tmux.git']='~/tmux'
    ['git@github.com:dtrip/zshrc.git']='~/zshrc'
    ['git@github.com:dtrip/powerline-shell.git']='~/powerline-shell'
    ['git://github.com/sstephenson/rbenv.git']='/usr/local/share/rbenv'
    ['git://github.com/wpscanteam/wpscan.git']='/usr/local/share/wpscan'
    ['git://github.com/sstephenson/ruby-build.git']='/usr/local/share/ruby-build'
)


PKG='vim tmux python-pip build-essential libpcap-dev libssl-dev git git-extras git-core'
PIP='powerline-status'

read -e -p "Please enter country code for apt sources.list " -i "[us]: " CCODE

echo "Installing packages from Ubuntu Repositories... "

log_daemon_msg "Updating package list..."
if sudo apt-get -qq -y update;
    then log_end_msg 0 else log_end_msg 1
fi

log_daemon_msg "Installing packages"
if sudo apt-get install -qq -y $PKG; 
    then log_end_msg 0 else log_end_msg 1
fi

log_daemon_msg "Install python pip packages"
    if sudo pip -q install $PIP;
then log_end_msg 0 else log_end_msg 1
fi

# refresh shell right quick
exec $SHELL

read -e -p "Please enter your username to create new user - leave blank to skip: " UNAME

if [ ! -z "$UNAME" ]; then
    log_daemon_msg "Creating new user $UNAME ..."
    if adduser $UNAME;
        then log_end_msg 0 else log_end_msg 1
    fi

    log_daemon_msg "switching users ..."
    if su $UNAME; 
        then log_end_msg 0 else log_end_msg 1
    fi
fi

# moves to users home directory
cd ~/

if sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)";
    then log_end_msg 0 else log_end_msg 1
fi


for GITURL in "${!GIT[@]}";
do
    log_daemon_msg "Cloning $GITURL into ${GIT["$GITURL"]}"
    if sudo git clone -q $GITURL "${GIT["$GITURL"]}"; 
    then log_end_msg 0 else log_end_msg 1
   
fi
done

# if entered a username, will fix home permissions from sudo git clone repos
if [ ! -z "$UNAME" ]; then
    log_daemon_msg "Fixing /home permissions"
    if sudo chown $UNAME:$UNAME -R /home/$UNAME && sudo chmod 755 -R /home/$UNAME;
        then log_end_msg 0 else log_end_msg 1
    fi

    # sets shell to zsh
    if sed -i -e "s/\/home\/$UNAME:\/bin\/bash/\/home\/$UNAME:\/bin\/zsh/g" /etc/passwd;
        then log_end_msg 0 else log_end_msg 1
    fi
fi

#updates submodules
log_daemon_msg "Updating zshrc submodules "
if cd ~/zshrc && git submodule update --init; 
    then log_end_msg 0 else log_end_msg 1
fi

log_daemon_msg "Adding powerline-shell zsh function"
if cat powerline-status-func.txt >> ~/.zshrc; 
    then log_end_msg 0 else log_end_msg 1
fi

log_daemon_msg "Setting up rbenv environment variables ..."
    if echo "export RBENV_ROOT=/usr/local/share/rbenv\nexport PATH=\"$RBENV_ROOT/bin:$PATH\"\neval \"$(rbenv init - zsh)\"\nsource $RBENV_ROOT/completions/rbenv.zsh" >> ~/.zshrc;
then log_end_msg 0 else log_end_msg 1
fi

log_daemon_msg "Setting up ruby-build"
    if cd /usr/local/share/ruby-build && sh install.sh; 
then log_end_msg 0 else log_end_msg 1
fi

exec $SHELL

read -e -p "Enter ruby version to install [2.2.2]: " RUBYV

if [ -z $RUBYV ]; then
    RUBYV='2.2.2'
fi
    log_daemon_msg "Installing ruby v${RUBYV}..."
        if rbenv install $RUBYV; 
    then log_end_msg 0 else log_end_msg 1
fi

    log_daemon_msg "setting global ruby version to ${RUBYV}..."
        if rbenv global $RUBYV;
    then log_end_msg 0 else log_end_msg 1
fi

    log_daemon_msg "rbenv rehashing..."
        if rbenv rehash; 
    then log_end_msg 0 else log_end_msg 1
fi

read -e -p "Would you like to install Metasploit? [Y/n]: " MSF


log_daemon_msg "Running vim setup"
if sh ~/.vim/install; 
    then log_end_msg 0 else log_end_msg 1
fi

cd $MSFPATH;

if sudo rbenv install 2.1.6;
then log_end_msg 0 else log_end_msg 1
fi

if sudo gem install bundler;
    then log_end_msg 0 else log_end_msg 1
fi

if sudo bundle install; 
then log_end_msg 0 else log_end_msg 1
fi

if sudo bash -c 'for MSF in $(ls msf*); do ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF;done';
    then log_end_msg 0 else log_end_msg 1
fi

echo "Finished!"
exit 0
