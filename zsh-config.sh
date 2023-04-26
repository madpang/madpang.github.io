# HOW:
# - create a symbolic link at $HOME/.zshrc

NAME=`scutil --get LocalHostName`
if [[ $NAME == 'PD-Panda' ]]; then
	# set terminal database for TMUX
	export TERMINFO="/opt/homebrew/Cellar/ncurses/6.4/share/terminfo"
	# note the Hombrew env. is handled by auto-generated `.zprofile` after the installation
else
	echo 'Unkonwn host.'
fi
