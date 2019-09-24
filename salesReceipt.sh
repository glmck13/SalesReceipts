#!/bin/ksh

xls="${1:?}" txt="${xls// /-}" txt=${txt%.*}.txt
export QBO_ITEMS=$HOME/etc/qboItems.csv
export QBO_SANDBOX=nextapp-

trap "rm -f $txt" HUP INT QUIT TERM EXIT

ssconvert -O 'quoting-mode=never separator=| format=preserve charset=ascii' "$xls" "$txt" 2>/dev/null

delim=""

(
print "{"

while IFS='|' read qty desc x x amt dow x brk tot brkamt totamt x
do
	if [[ "$dow" == *,*,* ]]; then
		print '"TxnDate":' \"$(date --date="$dow" "+%Y-%m-%d")\", '"Line": ['
		qty=""

	elif [[ "$totamt" == Page* ]]; then
		print ']'
		qty=""

	elif expr "$qty" : "^[[:digit:]]\+$" >/dev/null; then
		[ "$qty" -le 0 ] && qty=""

	elif [[ "$tot" == Services\ Sub\ Total ]]; then
		amt=$totamt amt=${amt#$} amt=${amt// /}
		if [[ "$amt" == 0* ]]; then
			qty=""
		else
			desc="$tot" qty="1"
		fi

	elif [[ "$brk" == Deposits* ]]; then
		if [[ "$brkamt" == 0* ]]; then
			qty=""
		elif [[ "$brk" == *Used ]]; then
			amt="-$brkamt" desc="$brk" qty="1"
		else
			amt="$brkamt" desc="$brk" qty="1"
		fi

	elif [[ "$brk" == @(Sales\ Tax|Paid\ On\ Account) ]]; then
		if [[ "$brkamt" == 0* ]]; then
			qty=""
		else
			amt="$brkamt" desc="$brk" qty="1"
		fi

	else
		qty=""
	fi

	if [ "$qty" ]; then
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
	fi

done <$txt

print "}"
) | tee ${txt%.*}-req.json | qbo.sh POST '/company/$QBO_REALMID/salesreceipt' | tee ${txt%.*}-rsp.json
