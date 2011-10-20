<?php
#
# check_mem.pl PNP4Nagios template
#
# v1.0 2011-01-28 GS <goesta@smekal.at>
# v2.0 2011-10-19 A Munro <armunro@gmail.com>
#   Customised for my client. Changed Kb into automatically scaling for cur/max/min.
#   Convert kb into bytes for areas so they have the proper scales.
#   Actually gets the graphs right; USED needs CACHE subtracting from it.
#   Set rrd base to 1024 rather than 1000 so vertical scales are correct.
#   Don't trust FREE figures from collector; sometimes free is the same size as
#   USED and CACHE; instead deducted CACHE and USED from total.
#
#$opt[1] = "--title \"Statistics for $servicedesc on $hostname\" -l 0 -u $MAX[2] -b 1024 ";
$opt[1] = "--title \"Statistics for $servicedesc on $hostname\" -l 0 -b 1024 ";

$actby=$ACT[1]*1024; # Convert kb to bytes.

$def[1] = "DEF:totalkb=$RRDFILE[1]:$DS[1]:AVERAGE ";
$def[1] .= "CDEF:totalby=totalkb,1024,* ";
$def[1] .= "HRULE:$actby#000000:\"$NAME[1]\" ";
$def[1] .= "GPRINT:totalby:LAST:\" %2.2lf %sb\\n\" ";
#$def[1] .= "HRULE:$WARN[2]#ffff00:\"Warning on $WARN[2] KB \" ";
#$def[1] .= "HRULE:$CRIT[2]#ff0000:\"Critical on $CRIT[2] KB\\n\" ";

$def[1] .= "DEF:cachekb=$RRDFILE[4]:$DS[4]:AVERAGE ";
$def[1] .= "CDEF:cacheby=cachekb,1024,* ";
$def[1] .= "AREA:cacheby#99ccff:\"$NAME[4]\":STACK ";
$def[1] .= "GPRINT:cacheby:LAST:\"%2.2lf %sb cur\" ";
$def[1] .= "GPRINT:cacheby:MAX:\"%2.2lf %sb max\" ";
$def[1] .= "GPRINT:cacheby:MIN:\"%2.2lf %sb min\\n\" ";

$def[1] .= "DEF:usedtotalkb=$RRDFILE[2]:$DS[2]:AVERAGE ";
$def[1] .= "CDEF:usedkb=usedtotalkb,cachekb,- ";
$def[1] .= "CDEF:usedby1=usedkb,1024,* ";

# Sometimes get negative numbers for USED, which when
# stacked against CACHE, subtracts its negative value
# from the CACHE area. Thus if its negative (less than zero)
# it must be wrong so set it to zero.

$def[1] .= "CDEF:usedby=usedby1,0,LT,0,usedby1,IF ";

$def[1] .= "AREA:usedby#ff9999:\"$NAME[2]\":STACK ";
$def[1] .= "GPRINT:usedby:LAST:\"  %2.2lf %sb cur\" ";
$def[1] .= "GPRINT:usedby:MAX:\"%2.2lf %sb max\" ";
$def[1] .= "GPRINT:usedby:MIN:\"%2.2lf %sb min\\n\" ";

#$def[1] .= "DEF:freekb=$RRDFILE[3]:$DS[3]:AVERAGE ";
#$def[1] .= "CDEF:freeby=freekb,1024,* ";
$def[1] .= "CDEF:freeby=totalby,cacheby,-,usedby,- ";
$def[1] .= "AREA:freeby#99ff99:\"$NAME[3]\":STACK ";
$def[1] .= "GPRINT:freeby:LAST:\"  %2.2lf %sb cur\" ";
$def[1] .= "GPRINT:freeby:MAX:\"%2.2lf %sb max\" ";
$def[1] .= "GPRINT:freeby:MIN:\"%2.2lf %sb min\\n\" ";

?>
