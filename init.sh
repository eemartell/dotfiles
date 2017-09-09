#!/bin/bash

### 0. init.sh Setup

# Function that checks if something is installed
# Usage: notinstalled <program>
notinstalled() {
  if [[ -n "$(which $1)" ]]; then
    return 1
  else
    return 0
  fi
}

# Colors: see https://stackoverflow.com/questions/2924697/how-does-one-output-bold-text-in-bash
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

# Length of time before timing out
timeout_length="2s"

# Function that prints the result of timeout downloading
# Usage: timeout_result <retcode> <filename>
function timeout_result {
    if [ $1 -eq 124 ]; then
        echo "${red}Killed downloading $2: timed out${normal}"
    else
        echo "${green}Successfully downloaded $2${normal}"
    fi
}


### 1. Install Mac-specific things

case $OSTYPE in
    darwin*) # OS X
        if notinstalled brew; then
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi

        brew install coreutils
        brew install emacs
        brew install tmux
        brew install wget

        mytimeout=gtimeout
        ;;

    *)
        mytimeout=timeout
        ;;
esac


### 2. Link dotfiles

thisdir=$(dirname $0)
cd $HOME

# Create symlinks
for file in ".bashrc" ".tmux.conf" ".emacs" ".emacs-modes.el" ".gitconfig"; do
    if [ -L $file ]; then
        echo "${red}Did not link $file: symlink already exists${normal}"
    elif [ ! -f $file ]; then
        ln -s "$thisdir/$file" $file
        echo "${green}Linked $file${normal}"
    else
        echo "${red}Did not link $file: non-symlink file already exists. Merge $file into $thisdir/$file first and then delete $file before retrying${normal}"
    fi
done

# Create local dotfiles if they don't already exist
for file in ".bashrc-local" ".gitconfig-local"; do
    if [ ! -f $file ]; then
        touch $file
        echo "${green}Created $file${normal}"
    fi
done


### 3. Clone necessary packages into .emacs.d, timing out after $timeout_length if necessary

# Create .emacs.d if it doesn't already exist
if [ ! -d "$HOME/.emacs.d" ]; then
    mkdir "$HOME/.emacs.d"
    echo "${green}Created .emacs.d${normal}"
fi

# Create .emacs.d/backup if it doesn't already exist
if [ ! -d "$HOME/.emacs.d/backup" ]; then
    mkdir "$HOME/.emacs.d/backup"
    echo "${green}Created .emacs.d/backup${normal}"
fi

cd "$HOME/.emacs.d"

# cl-lib
$mytimeout $timeout_length wget "https://elpa.gnu.org/packages/cl-lib-0.5.el"
timeout_result $? "cl-lib"

# Git
$mytimeout $timeout_length git clone "https://github.com/magit/git-modes.git"
timeout_result $? "git-modes"

# Julia
$mytimeout $timeout_length git clone "https://github.com/JuliaEditorSupport/julia-emacs.git"
timeout_result $? "julia-emacs"

# Markdown
$mytimeout $timeout_length git clone "https://github.com/defunkt/markdown-mode.git"
timeout_result $? "markdown-mode"

# MATLAB
$mytimeout $timeout_length wget "matlab-emacs.cvs.sourceforge.net/viewvc/matlab-emacs/matlab-emacs/?view=tar"
timeout_result $? "matlab-emacs"
if [ -f $file ]; then
    tar -zxvf "index.html?view=tar"
    rm "index.html?view=tar"
fi
