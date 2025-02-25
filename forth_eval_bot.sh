#!/bin/bash

BOT_NAME="gforth_eval_bot"
CHANNELS="#bsah ##forth"
export TERM="" # to prevent gforth from printing ascii colors

if [[ ! -p chat ]]; then
    mkfifo chat
fi

if [[ -f log ]]; then
    rm log
fi

{
    # Initialization
    printf "NICK %s\r\n" "${BOT_NAME}";
    printf "USER %s 0 * :%s\r\n" "${BOT_NAME}" "${BOT_NAME}";
    # Initialization completed

    for CHANNEL in ${CHANNELS[@]};
    do
printf "JOIN ${CHANNEL}\r\n";
    done

    while read -r line; do
# do something with the received raw command
if [[ $line =~ "PING" ]]; then
	printf "PONG\r\n";
fi
regex='^:([^!]*)!([^@]*)@([^ ]*) ([^ ]*) ([^ ]*) :(.*)'
# extracting nickname, channel name and message from the input
if ! [[ $line =~ $regex ]]; then echo "Something weird happened" >> log; continue; fi
SENDER_NICKNAME="${BASH_REMATCH[1]}"
TARGET="${BASH_REMATCH[5]}"
MESSAGE="${BASH_REMATCH[6]}"
COMMAND="${BASH_REMATCH[4]}"
echo "${line}" >> log;
echo "MESSAGE: ${MESSAGE}" >> log
echo "COMMAND: ${COMMAND}" >> log
if [[ $COMMAND == "PRIVMSG" ]]; then
	if [[ $MESSAGE =~ ^'!gforth '(.*) ]]; then
		echo "OUTPUT: ${OUTPUT}" >> log
		if [[ $TARGET != "$BOT_NAME" ]]; then
		    mapfile -t output_lines < <(timeout 1s docker run --rm rundockerforth/gforth --evaluate "${BASH_REMATCH[1]}" --evaluate "bye" 2>&1 | tr -d \\r | fold -w 128)
		    printf "PRIVMSG ${TARGET} :${output_lines[0]}\r\n";
		    if [[ ${#output_lines[@]} -gt 1 ]]; then
			    LINK=$(printf "%s\n" "${output_lines[@]}" | curl -F 'file=@-' https://0x0.st);
			    printf "PRIVMSG ${TARGET} :${LINK}\r\n";
		    fi
		fi
	fi
fi
    done < chat
} |  nc irc.libera.chat 6667 > chat

