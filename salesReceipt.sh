#!/bin/ksh

XlsFile=${1:?}
TxtFile=${XlsFile%.*}.txt
export QBO_ITEMS=$HOME/etc/qboItems.csv
export QBO_SANDBOX=nextapp-

trap "rm -f $TxtFile" HUP INT QUIT TERM EXIT

ssconvert -O 'quoting-mode=never separator=| format=preserve charset=ascii' $XlsFile $TxtFile 2>/dev/null

txndate=$(grep "^|||||.*, .*, .*|||||" $TxtFile) txndate=${txndate//\|/}
(
	cat - <<-EOF
	{
	"TxnDate": "$(date --date="$txndate" "+%Y-%m-%d")",
	"Line": [
	EOF

	delim=""

	grep '^[[:digit:]]\+|' $TxtFile | while IFS='|' read qty desc x x amt x
	do
		[ "$qty" -le 0 ] && continue
		grep -F "$desc|" $QBO_ITEMS | IFS='|' read x item val
		[ ! "$item" ] && item="$desc"
		[ "$delim" ] && print ","
		cat - <<-EOF
		{
		"DetailType": "SalesItemLineDetail",
		"Description": "$desc",
		"Amount": ${amt//,/},
		"SalesItemLineDetail": {
		"Qty": $qty,
		"ItemRef": {
		"name": "$item",
		"value": "$val"
		}
		}
		}
		EOF
		delim="y"
	done

	cat - <<-EOF
	]
	}
	EOF
) | qbo.sh POST '/company/$QBO_REALMID/salesreceipt'
