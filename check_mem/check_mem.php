<?php
#
# check_mem.pl PNP4Nagios template
# v1.1 2011-12-20  
#

$ds_name[1] = "Memory Usage";
$opt[1] = "--title \"Statistics for $servicedesc on $hostname\" -l 0 -u $MAX[2] ";

$def[1] = "DEF:total=$RRDFILE[1]:$DS[1]:AVERAGE ";
$def[1] .= "AREA:".($ACT[1]*1024)."#E0FFE0:\"$NAME[1]\t\" ";
$def[1] .= "COMMENT:\"".$ACT[1]." ".$UNIT[1]." \\n\" ";

$def[1] .= "DEF:used=$RRDFILE[2]:$DS[2]:AVERAGE ";
$def[1] .= "CDEF:used_b=used,1024,* ";
$def[1] .= "AREA:used_b#ff9999:\"$NAME[2]\t\" ";
$def[1] .= "GPRINT:used:LAST:\"%2.2lf ".$UNIT[2]." curr\" ";
$def[1] .= "GPRINT:used:MAX:\"%2.2lf ".$UNIT[2]." max\" ";
$def[1] .= "GPRINT:used:MIN:\"%2.2lf ".$UNIT[2]." min\\n\" ";

################################################################
# Uncomment the following section to make the Cache
# appear on the graph
################################################################

$def[1] .= "DEF:cache=$RRDFILE[4]:$DS[4]:AVERAGE ";
$def[1] .= "CDEF:cache_b=cache,1024,* ";
$def[1] .= "AREA:cache_b#99ccff:\"$NAME[4]\":STACK ";
$def[1] .= "GPRINT:cache:LAST:\"%2.2lf ".$UNIT[4]." curr\" ";
$def[1] .= "GPRINT:cache:MAX:\"%2.2lf ".$UNIT[4]." max\" ";
$def[1] .= "GPRINT:cache:MIN:\"%2.2lf ".$UNIT[4]." min\\n\" ";

# Plot free memory - note if -C is used, free memory will include caches
# This plot will stack on top of caches and appear to exceed the total memory, because the caches are stacked twice
#$def[1] .= "DEF:free=$RRDFILE[3]:$DS[3]:AVERAGE ";
#$def[1] .= "CDEF:free_b=free,1024,* ";
#$def[1] .= "AREA:free_b#99ff99:\"$NAME[3]\t\":STACK ";
#$def[1] .= "GPRINT:free:LAST:\"%2.2lf ".$UNIT[3]." curr\" ";
#$def[1] .= "GPRINT:free:MAX:\"%2.2lf ".$UNIT[3]." max\" ";
#$def[1] .= "GPRINT:free:MIN:\"%2.2lf ".$UNIT[3]." min\\n\" ";

# Same again, with a line for emphasis
# These lines go last, so they don't get drawn over by the area graphs
$def[1] .= "LINE:".($ACT[1]*1024)."#40C040:: ";
$def[1] .= "LINE:used_b#C04040: ";
$def[1] .= "LINE:cache_b#4040C0::STACK ";
#$def[1] .= "LINE:free_b#4080C0::STACK ";

if($WARN[2] != ""){
  	$def[1] .= rrd::hrule($WARN[2]*1024, "#FFFF00", "Warning  ".$WARN[2].$UNIT[2]."\\n");
}
if($CRIT[2] != ""){
  	$def[1] .= rrd::hrule($CRIT[2]*1024, "#FF0000", "Critical ".$CRIT[2].$UNIT[2]."\\n");
}

#error_log($def[1]);
#error_log("WARN: ". implode(", ",array_values($WARN)). "   WARN 2 = $WARN[2]   UNIT 2  = $UNIT[2]");
#error_log("CRIT: ". implode(", ",array_values($CRIT)) . "   CRIT 2 = $CRIT[2]   UNIT 2  = $UNIT[2]");
?>
