#!/bin/bash
#
# fetch site-logs for SAPOS stations from https://sapos.bayern.de
#
# Alexandr Sokolov, KEG
# 10.04.2017

cd /home/gast/SAPOS/Logfiles/.

list_SAPOS="0256 0257 0258 0259 0260 0261 0264 0265 0266 0267 0268 0269 0270 0272 0273 0276 0278 0279 0280 0281 0282 0283 0284 0285 0286 0287 0288 0289 0292 0293 0294 0295 0296 1271 1275 1277 1291 2274"

for Site in $list_SAPOS
do {
	echo "Site:$Site"
	wget -nv https://sapos.bayern.de/refmap.php?detail=$Site

	grep '(site log)' refmap.php\?detail\="$Site" --after-context=1000 |  sed  -- 's/wrap="off">/wrap="off">\n/g' > q
	grep 'textarea' q --before-context=1000 | grep -v 'textarea' > q2

	rm refmap.php?detail="$Site"

	datePrepared=$(grep 'Date Prepared'     q2 | cut -c33-42 | sed  's/-//g')
	code=$(        grep 'Four Character ID' q2 | cut -c33-36)
	
	old_log=$(ls -1 "$Site"*.log)	
	new_log="$code"_"$datePrepared".log				
	cat q2 > "$code"_"$datePrepared".log
	
	if [ "$old_log" != "$new_log" ]; then
		mv $old_log old/.
	fi
	
	if [ -f "$new_log" ]; then
		echo "$new_log site-log downloaded"
	fi
} done

rm q q2 




