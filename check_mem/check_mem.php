<?php
#
# check_mem.pl PNP4Nagios template
#
# v1.0 2011-01-28 GS <goesta@smekal.at>
#
$opt[1] = "--title \"Statistics for $servicedesc on $hostname\" -l 0 -u $MAX[2] ";

$def[1] = "DEF:total=$RRDFILE[1]:$DS[1]:AVERAGE ";
$def[1] .= "HRULE:$ACT[1]#000000:\"$NAME[1]\t\" ";
$def[1] .= "GPRINT:total:LAST:\"%2.2lf ".$UNIT[1]."\" ";
$def[1] .= "HRULE:$WARN[2]#ffff00:\"Warning on $WARN[2] KB \" ";
$def[1] .= "HRULE:$CRIT[2]#ff0000:\"Critical on $CRIT[2] KB\\n\" ";

$def[1] .= "DEF:used=$RRDFILE[2]:$DS[2]:AVERAGE ";
$def[1] .= "AREA:used#ff9999:\"$NAME[2]\t\" ";
$def[1] .= "GPRINT:used:LAST:\"%2.2lf ".$UNIT[2]." curr\" ";
$def[1] .= "GPRINT:used:MAX:\"%2.2lf ".$UNIT[2]." max\" ";
$def[1] .= "GPRINT:used:MIN:\"%2.2lf ".$UNIT[2]." min\\n\" ";

$def[1] .= "DEF:cache=$RRDFILE[4]:$DS[4]:AVERAGE ";
$def[1] .= "AREA:cache#99ccff:\"$NAME[4]\t\":STACK ";
$def[1] .= "GPRINT:cache:LAST:\"%2.2lf ".$UNIT[4]." curr\" ";
$def[1] .= "GPRINT:cache:MAX:\"%2.2lf ".$UNIT[4]." max\" ";
$def[1] .= "GPRINT:cache:MIN:\"%2.2lf ".$UNIT[4]." min\\n\" ";

$def[1] .= "CDEF:free=total,used,-,cache,- ";
$def[1] .= "AREA:free#99ff99:\"$NAME[3]\t\":STACK ";
$def[1] .= "GPRINT:free:LAST:\"%2.2lf ".$UNIT[3]." curr\" ";
$def[1] .= "GPRINT:free:MAX:\"%2.2lf ".$UNIT[3]." max\" ";
$def[1] .= "GPRINT:free:MIN:\"%2.2lf ".$UNIT[3]." min\\n\" ";
?>
