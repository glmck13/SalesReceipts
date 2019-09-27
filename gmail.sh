#!/bin/ksh

PATH=$PWD:$HOME/bin:/usr/local/bin:$PATH

INBOX=$HOME/gmail; cd $INBOX
email=""

o2Refresh.sh >/dev/null

subject="Sales Receipts" message=""

gmail.py | while read sheet
do
	if [ ! "$sheet" ]; then
		:

	elif [[ "$sheet" == *@* ]]; then
		addr="$sheet"
		addr=${addr#*<} addr=${addr%>*}
		addr=$(print "$addr" | sed -e 's/[-() "]//g')
		[ "$email" ] && email+=","
		email+="$addr"

	else
		salesReceipt.sh "$sheet" | tr ',' '\n' | grep TotalAmt | read response
		message+="$sheet:${response##*:}\r"
		#rm -f $sheet
	fi
done

sendsms.sh "$email" "$subject" "$message"
