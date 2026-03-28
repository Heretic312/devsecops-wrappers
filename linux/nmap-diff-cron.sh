#!/bin/bash
mkdir /opt/nmap_
diff
d=$(date +%Y-%m-%d)
y=$(date -d yesterday +%Y-%m-%d)
/usr/bin/nmap -T4 -oX /opt/nmap_
diff/scan
$d.xml 10.100.100.0/24 >
_
/dev/null 2>&1
if [ -e /opt/nmap_
diff/scan
_
$y.xml ]; then
/usr/bin/ndiff /opt/nmap_
diff/scan
_
$y.xml /opt/nmap_
diff/scan
$d.xml >
_
/opt/nmap_
diff/diff.txt
fi