#!/bin/bash

# skip the slow apt update + ppa re-add when apt-fast/parallel are already set up
# downstream scripts run their own apt update, and a fresh machine (no apt-fast
# yet) still falls through to the full bootstrap below
if [[ -n "${DOTFILES_SKIP_SATISFIED_DEPS:-}" ]] \
    && command -v apt-fast >/dev/null 2>&1 \
    && command -v parallel >/dev/null 2>&1 \
    && [[ -e /etc/apt-fast.conf ]]; then
    echo "apt-fast + parallel already set up; skipping bootstrap"
    exit 0
fi

safer-apt update
# software-properties-common adds `add-apt-repository` 
safer-apt install software-properties-common
# https://github.com/ilikenwf/apt-fast
safer-add-apt-repository 'ppa:apt-fast/stable' || echo "WARNING: apt-fast PPA unreachable; safer-apt-fast will fall back to plain apt"
safer-apt update
config-apt-fast() {
    # Skip configuration if apt-fast didn't end up installed (e.g., PPA was unreachable)
    if ! command -v apt-fast >/dev/null 2>&1; then
        return 0
    fi
    sudo rm -f /etc/apt-fast.conf
    sudo ln -s $HOME/dotfiles/configs/packages/apt-fast.conf /etc/apt-fast.conf
}
safer-apt install apt-fast
config-apt-fast

# We need gnu parallel to run our dotfiles faster (async)
# https://superuser.com/questions/1659206/run-background-async-cmd-with-sync-output
# safer-apt-fast falls through to plain apt if apt-fast wasn't installed above
safer-apt-fast install parallel
