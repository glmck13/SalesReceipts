#!/bin/ksh

PATH=$PWD:$HOME/bin:$PATH

export QBO_SANDBOX=nextapp-
INBOX=$HOME/gmail; cd $INBOX
email=""

o2Refresh.sh

message=""
gmail.py | while read sheet
do
	if [ ! "$sheet" ]; then
		:

	elif [[ "$sheet" == *@* ]]; then
		[ "$email" ] && email+=","
		email+="$sheet"

	else
		salesReceipt.sh "$sheet" | tr ',' '\n' | grep TotalAmt | read response
		message+="$sheet:${response##*:}\r"
		#rm -f $sheet
	fi
done

if [ "$message" ]; then
export TERM=xterm
expect >/dev/null <<EOF
set timeout 120
spawn alpine "$email"
expect "To AddrBk"
send "Sales Receipts\r$message\rY"
expect "Alpine finished"
EOF
fi
