#!/bin/sh


# 1. 安装rz/sz:
#     brew install lrzsz
#
# 2. 把本脚本放置在/usr/local/bin目录，并设置可执行权限:
#     chmod +x /usr/local/bin/iterm2-zmodem.sh
#
# 3. 在iTerm2里添加两个触发器: 'Preferences...' -> 'Profiles' -> 'Advanced' -> 'Trigger', 单击 'Edit', 单击左下角“+”号
#     触发器参数如下:
#     Regular expression: rz waiting to receive.\*\*B0100
#     Action: Run Silent Coprocess
#     Parameters: /usr/local/bin/iterm2-zmodem.sh send
#     Instant: checked
#
#     Regular expression: \*\*B00000000000000
#     Action: Run Silent Coprocess
#     Parameters: /usr/local/bin/iterm2-zmodem.sh recv
#     Instant: checked


SEND_DIALOG_TITLE="Send File - Zmodem"
RECEIVE_DIALOG_TITLE="Receive File - Zmodem"
LRZSZ_HOME=${HOMEBREW_PREFIX:-/usr/local}/bin

cancel_zmodem() {
	# Send ZModem cancel
	printf "\x18\x18\x18\x18\x18"
}

alert() {
	msg="$1"
	title="${2:-$(basename "$0")}"
	icon="${3:-caution}" # stop | note | caution

	osascript <<-EOF 2>/dev/null
		tell application "iTerm2"
			activate
			display dialog "$msg" buttons {"OK"} default button 1 with title "$title" with icon $icon
			return -- Suppress result
		end tell
	EOF
}

send_file() {
	file_path="$(
		osascript <<-EOF 2>/dev/null
			tell application "iTerm2"
				activate
				set filePath to (choose file with prompt "Select a file to send")
				do shell script "echo " & (quoted form of POSIX path of filePath as Unicode text)
			end tell
		EOF
	)"

	if [ -z "$file_path" ] ; then
		cancel_zmodem

		sleep 1 # sleep to make next "echo" works

		echo
		exit 0
	fi

	if ${LRZSZ_HOME}/sz "$file_path" -b -B 4096 -e -E 2>/dev/null ; then
		alert "File sent to remote: $file_path" "$SEND_DIALOG_TITLE" "note"

		echo
	else
		cancel_zmodem

		alert "Transfer failed when send file: $file_path" "$SEND_DIALOG_TITLE" "stop"

		echo
		exit 1
	fi
}

recv_file() {
	folder_path="$(
		osascript <<-EOF 2>/dev/null
			tell application "iTerm2"
				activate
				set folderPath to (choose folder with prompt "Select a folder to receive file")
				do shell script "echo " & (quoted form of POSIX path of folderPath as Unicode text) & " | sed 's|:/$|/|'"
			end tell
		EOF
	)"

	if [ -z "$folder_path" ] ; then
		cancel_zmodem

		sleep 1

		echo
		exit 0
	fi

	if [ ! -d "$folder_path" ] ; then
		cancel_zmodem

		alert "Can't find local folder: $folder_path" "$RECEIVE_DIALOG_TITLE" "stop"

		echo
		exit 1
	else
		if ! cd "$folder_path" ; then
			cancel_zmodem

			alert "Can't open local folder: $folder_path" "$RECEIVE_DIALOG_TITLE" "stop"

			echo
			exit 1
		fi

		if ${LRZSZ_HOME}/rz -b -B 4096 -e -E 2>/dev/null ; then
			cd - || true

			alert "File saved to local folder: $folder_path" "$RECEIVE_DIALOG_TITLE" "note"

			echo
		else
			cancel_zmodem

			alert "Transfer failed when recevie file" "$RECEIVE_DIALOG_TITLE" "stop"

			echo
			exit 1
		fi
	fi
}

action=${1:-"noop"}
if [ "$action" = "send" ] ; then
	send_file

elif [ "$action" = "recv" ] ; then
	recv_file

else
	cancel_zmodem

	alert "Usage: $(basename "$0") recv|send"

	echo
	exit 128
fi
