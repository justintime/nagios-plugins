#
# check_mem.pl PNP4Nagios template
# v1.1 2011-12-20  
#

$opt[1] = "--title \"Statistics for $servicedesc on $hostname\" -l 0 -u $MAX[2] ";

$def[1] = "DEF:total=$RRDFILE[1]:$DS[1]:AVERAGE ";
$def[1] .= "AREA:$ACT[1]#FFFFFF:\"$NAME[1]\t\" ";

$def[1] .= "DEF:used=$RRDFILE[2]:$DS[2]:AVERAGE ";
$def[1] .= "AREA:used#ff9999:\"$NAME[2]\t\" ";
$def[1] .= "GPRINT:used:LAST:\"%2.2lf ".$UNIT[2]." curr\" ";
$def[1] .= "GPRINT:used:MAX:\"%2.2lf ".$UNIT[2]." max\" ";
$def[1] .= "GPRINT:used:MIN:\"%2.2lf ".$UNIT[2]." min\\n\" ";

$def[1] .= "DEF:free=$RRDFILE[3]:$DS[3]:AVERAGE ";
$def[1] .= "AREA:free#99ff99:\"$NAME[3]\t\":STACK ";
$def[1] .= "GPRINT:free:LAST:\"%2.2lf ".$UNIT[3]." curr\" ";
$def[1] .= "GPRINT:free:MAX:\"%2.2lf ".$UNIT[3]." max\" ";
$def[1] .= "GPRINT:free:MIN:\"%2.2lf ".$UNIT[3]." min\\n\" ";


################################################################
# Uncomment the following section to make the Cache
# appear on the graph
################################################################

# $def[1] .= "DEF:cache=$RRDFILE[4]:$DS[4]:AVERAGE ";
# $def[1] .= "AREA:cache#99ccff:\"$NAME[4]\t\" ";
# $def[1] .= "GPRINT:cache:LAST:\"%2.2lf ".$UNIT[4]." curr\" ";
# $def[1] .= "GPRINT:cache:MAX:\"%2.2lf ".$UNIT[4]." max\" ";
# $def[1] .= "GPRINT:cache:MIN:\"%2.2lf ".$UNIT[4]." min\\n\" ";
?>