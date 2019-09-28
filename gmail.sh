#!/bin/ksh

PATH=$PWD:$HOME/bin:/usr/local/bin:$PATH

INBOX=$HOME/gmail; cd $INBOX
email=""

o2Refresh.sh >/dev/null

addr="" subject="Sales Receipts" message="" attach=""

gmail.py | while read sheet
do
	if [ ! "$sheet" ]; then
		:

	elif [[ "$sheet" == *@* ]]; then
		addr="$sheet"
		addr=${addr#*<} addr=${addr%>*}
		addr=$(print "$addr" | sed -e 's/[-() "]//g')

	else
		salesReceipt.sh "$sheet" | tr ',' '\n' | grep TotalAmt | read response
		message+="$sheet:${response##*:}\r"
		[ "$attach" ] && attach+=", "
		attach+="./$sheet"
	fi
done

[ "$addr" ] && sendaway.sh "$addr" "$subject" "$message"
[ "$email" ] && sendaway.sh "$email" "$subject" "$message" "$attach"
