#!/usr/bin/env zsh

# Color constants
yellow="\e[33;40m"
red="\e[31;40m"
green="\e[32;40m"
reset="\e[39;49m"

me=`basename $0`
echo "basename is: $me"

# Get options.
LNOPTS=""
if [ $# -gt 0 ]; then
  if [[ "$1" == "-f" ]]; then
    LNOPTS="-f"
  else
    echo "Unrecognized option: $1"
    cat << EOF
Usage: $me [OPTIONS]

    Options:
    -f    Force 'ln' to create a new link, even if one already exists with the
          same name.
EOF
    exit 1
  fi
fi

# The system name is used to link platform-specific files.
platform=`uname`
echo "current platform is: $platform"

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
BINPATH="$SCRIPTPATH/bin"
SCRIPTPATH="$SCRIPTPATH/misc"
popd > /dev/null

pushd ~ > /dev/null

echo "current BINPATH is: $BINPATH"
echo "Creating symlinks for all configuration files in $SCRIPTPATH"
echo ""

# setup ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 
rm -rf $HOME/.zshrc

for dotfile in `find $SCRIPTPATH -mindepth 1 -maxdepth 1`; do
    linkfile=".${dotfile##*/}"

    #if [ -d "./$linkfile" ]

    if [ -e "$linkfile" ]; then
        echo -n "${yellow}Exists${reset}"
    else
        ln -s $LNOPTS "$dotfile" "./$linkfile" > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo -n "${green}OK${reset}    "
        else
            echo -n "${red}Failed${reset}"
        fi
    fi

    echo " $dotfile -> $linkfile... "
done

if [ ! -d "$HOME/bin" ]; then
  echo "Creating ~/bin directory."
  mkdir "$HOME/bin"
fi

if [ ! -d "$HOME/.config" ]; then
	echo "Creating .config directory."
	mkdir "$HOME/.config"
fi


if [ ! -d "$HOME/.config/nvim" ]; then
	echo "Creating nvim directory."
	mkdir "$HOME/.config/nvim"
fi


# Return to original pwd.
popd > /dev/null

# setup applications
if [[ "$OSTYPE" == "linux-gnu" ]]; then
	sudo apt-get install silversearcher-ag -y
elif [[ "$OSTYPE" == "darwin"* ]]; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" 

	brew install the_silver_searcher
	brew install zsh
	brew install neovim
	brew install tmux
fi


# install vim-plug
if [ ! -d "$HOME/.config/nvim/autoload" ]; then
	echo "download... vim-plug."
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if [ ! -d "$HOME/.tmux/plugins" ]; then
	echo "download... tmux plugin manager."
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

ln -s $LNOPTS "`pwd`/init.vim" "$HOME/.config/nvim/init.vim" > /dev/null 2>&1
ln -s $LNOPTS "`pwd`/settings/alacritty.yml" "$HOME/.config/alacritty.yml" > /dev/null 2>&1

# force install pynvim
pip3 install pynvim
pip3 install --user neovim

# install vim plugin
nvim -c "PlugInstall"

# Move into bin dir.
pushd "$HOME/bin" > /dev/null

echo ""
echo "Creating symlinks for executable scripts in $BINPATH."
echo ""

for script in `find $BINPATH -mindepth 1 -maxdepth 1`; do
  linkfile="${script##*/}"
  ln -s $LNOPTS "$script" "$linkfile" > /dev/null 2>&1
  chmod +x $linkfile
  if [ $? -eq 0 ]; then
    echo -n "${green}OK${reset}    "
  else
    if [ -f "$linkfile" ]; then
      echo -n "${yellow}Exists${reset}"
    else
      echo -n "${red}Failed${reset}"
    fi
  fi
  echo " $script -> $linkfile... "
done

# Return to original pwd.
popd > /dev/null
