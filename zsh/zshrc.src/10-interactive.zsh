# Aliases and interactive shell configuration
function cdd {
    # Change pwd to directory in which $1 is located
    if [[ ! -e $1 ]]; then
        >&2 print -- '$1 does not exist'
        return 1
    fi
    cd ${1:A:h}
}

function cde {
    # Change current working directory to directory in which $1 is located,
    # and execute the command.
    if [[ ! -x $1 ]]; then
        >&2 print -- '$1 is not executable'
        return 1
    fi
    local prog=${1:A}
    local target_dir=${prog:h}
    pushd -q $target_dir
    shift 1
    $prog "$@"
    popd -q
}

alias cd=' cd'
alias cp='cp --reflink=auto'
alias grep='grep --color=auto'
alias help=run-help
function {
    local -a option
    # Test if --group-directories-first option is available
    ls --group-directories-first --version &> /dev/null && {
        option+=--group-directories-first
    }
    local color_auto
    local color_never
    if [[ $OSTYPE == freebsd* ]]; then
        color_auto='-G'
    else
        # Assume gnu ls
        color_auto='--color=auto'
        color_never='--color=never'
    fi
    alias la=" ls $color_auto $option -lha"
    alias lh=" ls $color_auto $option -lh"
    alias LH=" ls $color_never $option -lhF"
    alias ls="ls $color_auto"
}

function rf {
    local abspath
    abspath=${1:A}
    # if xclip is present, pipe output to xclip
    if (( ${+commands[xclip]} )); then
        print -n -- $abspath | tee >(xclip) >(xclip -selection clipboard) >(tmux load-buffer -)
    else
        print -n -- $abspath | tmux load-buffer -
    fi
}

# Productive Git aliases and functions
(( ${+commands[git]} )) && {
    function git-reset-to-remote-branch {
        git remote update --prune
        git reset --hard $(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
    }
    function grst {
        git tag -d $(git tag)
        git-reset-to-remote-branch
    }
    alias gco=' git checkout'
    alias gd=' git diff'
    alias gds=' git diff --staged'
    alias grh=' git reset --hard'
    alias gs=' git status'
    alias gsm=' git merge -s subtree --no-commit --squash'
    # Use alternate screen in git log
    alias lol=" git log --oneline --decorate --graph --color=auto"
    alias gpr=' git pull --rebase'
    alias grrr=' git-reset-to-remote-branch'
}
export GIT_PAGER='less -+F -+X -c'

(( ${+commands[docker]} )) && {
    local semver=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    local -a versions
    versions=(${(@s/./)semver})
    if (( ${#versions} == 3 )); then
        local major=${versions[1]}
        local minor=${versions[2]}
        if (( major >= 1 && minor >= 13)); then
            alias dksp=' docker system prune'
        fi
    fi
    alias dkcc=' docker-clear-containers'
    alias dkci=' docker-clear-images'
}

# vi = Vim without my plugins
#   The use of function keyword in function declaration
#   is to prevent vi get expanded to vim on some system
#   that alias vi=vim
(( ${+commands[vi]} )) && function vi {
    local VIMINIT=
    command vi "$@"
}
# unalias vi, because it can override previous vi function
(( ${+aliases[vi]} )) && unalias vi

# Prefer nvim
(( ${+commands[nvim]} )) && {
    function nvim {
        # Deactivate python virtual environment before start nvim
        if (( ${+functions[deactivate]} )) && [[ -n $VIRTUAL_ENV ]]; then
            (deactivate && command nvim "$@")
        else
            command nvim "$@"
        fi
    }
    alias neo=nvim
}

# Running from command line makes Pycharm inherite all environment variables
# This makes tools installed by npm using nvm work.
(( ${+commands[pycharm]} )) && alias pycharm=' nohup pycharm &> /dev/null &!'

alias fumount='fusermount -u'

# Fix multimonitor on kubuntu 16.04
if [[ $NMK_DEVELOPMENT == true ]]; then
    alias mm1='xrandr --output HDMI1 --off; xrandr --output eDP1 --primary --auto --pos 0x0 --rotate normal; reset-plasma5-panel.py'
    alias mm2='xrandr --output eDP1 --auto --pos 0x0 --rotate normal; xrandr --output HDMI1 --primary --auto --pos 1920x-100 --rotate normal; reset-plasma5-panel.py'
    # alias mm1='xrandr --output DVI-I-1 --off; xrandr --output HDMI1 --off; xrandr --output eDP1 --primary --auto --pos 0x0 --rotate normal; reset-plasma5-panel.py'
    # alias mm2='xrandr --output DVI-I-1 --off; xrandr --output eDP1 --auto --pos 0x0 --rotate normal; xrandr --output HDMI1 --primary --auto --pos 1920x-100 --rotate normal; reset-plasma5-panel.py'
    # alias mm3='xrandr --output DVI-I-1 --auto --pos 0x0 --rotate normal; xrandr --output HDMI1 --primary --auto --pos 1920x0 --rotate normal; xrandr --output eDP1 --auto --pos 3840x0 --rotate normal; reset-plasma5-panel.py'
fi

# apply tmux session environment to running shell
alias ssenv=' eval $(tmux show-environment -s)'

# Disable terminal flow control, so that we can use '^S'
# for history-search-forward.
stty -ixon
