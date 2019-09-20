#!/bin/ksh

PATH=$PWD:$HOME/bin:$PATH

export QBO_SANDBOX=nextapp-
INBOX=$HOME/gmail; cd $INBOX
EMAIL="mckenna5d@verizon.net,glmck13@verizon.net"

o2Refresh.sh

message=""
gmail.py | while read sheet
do
	salesReceipt.sh $sheet | tr ',' '\n' | grep TotalAmt | read response
	message+="$sheet:${response##*:}\r"
	#rm -f $sheet
done

export TERM=xterm
expect >/dev/null <<EOF
set timeout 120
spawn alpine "$EMAIL"
expect "To AddrBk"
send "Sales Receipts\r$message\rY"
expect "Alpine finished"
EOF
