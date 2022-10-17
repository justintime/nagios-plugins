#!/usr/bin/perl -w

# Heavily based on the script from:
# check_mem.pl Copyright (C) 2000 Dan Larsson <dl@tyfon.net>
# heavily modified by
# Justin Ellison <justin@techadvise.com>
#
# The MIT License (MIT)
# Copyright (c) 2011 justin@techadvise.com

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
# OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Tell Perl what we need to use
use strict;
use Getopt::Std;

#TODO - Convert to Nagios::Plugin
#TODO - Use an alarm

# Predefined exit codes for Nagios
use vars qw($opt_c $opt_f $opt_u $opt_a $opt_w $opt_C $opt_v $opt_h %exit_codes);
%exit_codes   = ('UNKNOWN' , 3,
                 'OK'      , 0,
                 'WARNING' , 1,
                 'CRITICAL', 2,
                 );

# Get our variables, do our checking:
init();

# Get the numbers:
my ($free_memory_kb,$used_memory_kb,$caches_kb,$available_memory_kb,$hugepages_kb) = get_memory_info();
print "$free_memory_kb Free\n$used_memory_kb Used\n$caches_kb Cache\n" if ($opt_v);
print "$available_memory_kb Available\n" if ($opt_v and $opt_a);
print "$hugepages_kb Hugepages\n" if ($opt_v and $opt_h);

if ($opt_C) { #Do we count caches as free?
    $used_memory_kb -= $caches_kb;
    $free_memory_kb += $caches_kb;
}

if ($opt_h) {
    $used_memory_kb -= $hugepages_kb;
}

print "$used_memory_kb Used (after Hugepages)\n" if ($opt_v);

# Round to the nearest KB
$free_memory_kb = sprintf('%.0f',$free_memory_kb);
$used_memory_kb = sprintf('%.0f',$used_memory_kb);
$caches_kb = sprintf('%.0f',$caches_kb);

# Tell Nagios what we came up with
tell_nagios($used_memory_kb,$free_memory_kb,$caches_kb,$available_memory_kb,$hugepages_kb);


sub tell_nagios {
    my ($used,$free,$caches,$available,$hugepages) = @_; # KB

    # Calculate Total Memory
    my $total = $free + $used;
    print "$total Total\n" if ($opt_v);

    # Absolute limits in KB
    my $limit_warn;
    my $limit_crit;

    # is level absolute
    my $is_abs_warn;
    my $is_abs_crit;
    my $type_check = "percentage";


    # WARN
    ($limit_warn, $is_abs_warn) = parameterize_thresholds($opt_w, "WARNING", $total);

    # CRITICAL
    ($limit_crit, $is_abs_crit) = parameterize_thresholds($opt_c, "CRITICAL", $total);

    # Check if both levels are absolute or percentage
    if ($is_abs_crit != $is_abs_warn) {
        print "WARNING and CRITICAL should be both absolute or percentage";
        &usage;
    }
    elsif ($is_abs_crit){
        $type_check = "absolute";
    }

    my $perf_warn;
    my $perf_crit;
    if ( $opt_u ) { # used
        $perf_warn = $limit_warn;
        $perf_crit = $limit_crit;
    } else { # free and available
        $perf_warn = $total - $limit_warn;
        $perf_crit = $total - $limit_crit;
    }

    # Check if levels are sane
    if ($limit_warn <= $limit_crit and ($opt_f or $opt_a)) {
        my $opt = ($opt_f eq 1 ? "FREE" : "AVAILABLE");
        print "*** WARNING level must not be less than CRITICAL when checking $opt memory!\n";
        &usage;
    }
    elsif ($limit_warn >= $limit_crit and $opt_u) {
        print "*** WARNING level must not be greater than CRITICAL when checking USED memory!\n";
        &usage;
    }

    my $perfdata = "|TOTAL=${total}MB;;;;";
    if ( !$opt_a ) {
      $perfdata .= " USED=${used}MB;${perf_warn};${perf_crit};;";
    } else {
      $perfdata .= " USED=${used}MB;;;;";
    }
    $perfdata .= " FREE=${free}MB;;;;";
    $perfdata .= " CACHES=${caches}MB;;;;";
    $perfdata .= " AVAILABLE=${available}MB;${perf_warn};${perf_crit};;" if ($opt_a);
    $perfdata .= " HUGEPAGES=${hugepages}MB;;;;" if ($opt_h);

    if ($opt_f) { # free
      my $percent    = sprintf "%.1f", ($free / $total * 100);
      if ($free < $limit_crit) {
          finish("CRITICAL - $percent% ($free MB) free-$type_check!$perfdata",$exit_codes{'CRITICAL'});
      }
      elsif ($free < $limit_warn) {
          finish("WARNING - $percent% ($free MB) free-$type_check!$perfdata",$exit_codes{'WARNING'});
      }
      else {
          finish("OK - $percent% ($free MB) free-$type_check.$perfdata",$exit_codes{'OK'});
      }
    }
    elsif ($opt_a) { # available
      my $percent    = sprintf "%.1f", ($available / $total * 100);
      if ($available  <= $limit_crit) {
          finish("CRITICAL - $percent% ($available MB) available-$type_check!$perfdata",$exit_codes{'CRITICAL'});
      }
      elsif ($available  <= $limit_warn) {
          finish("WARNING - $percent% ($available MB) available-$type_check!$perfdata",$exit_codes{'WARNING'});
      }
      else {
          finish("OK - $percent% ($available MB) available-$type_check.$perfdata",$exit_codes{'OK'});
      }
    }
    elsif ($opt_u) {  # used
      my $percent    = sprintf "%.1f", ($used / $total * 100);
      if ($used > $limit_crit) {
          finish("CRITICAL - $percent% ($used MB) used-$type_check!$perfdata",$exit_codes{'CRITICAL'});
      }
      elsif ($used > $limit_warn) {
          finish("WARNING - $percent% ($used MB) used-$type_check!$perfdata",$exit_codes{'WARNING'});
      }
      else {
          finish("OK - $percent% ($used MB) used-$type_check.$perfdata",$exit_codes{'OK'});
      }
    }
}

# Show usage
sub usage() {
  print "\ncheck_mem.pl v1.0 - Nagios Plugin\n\n";
  print "usage:\n";
  print " check_mem.pl -<f|u|a> -w <warnlevel> -c <critlevel>\n\n";
  print "options:\n";
  print " -a             Check AVAILABLE memory\n";
  print " -f             Check FREE memory\n";
  print " -u             Check USED memory\n";
  print " -C             Count OS caches as FREE memory\n";
  print " -w PERCENTAGE  Percent free/used/available when to warn\n";
  print " -w SIZE K/M/G  Absolute size free/used/available when to warn\n";
  print " -c PERCENTAGE  Percent free/used/available when critical\n";
  print " -c SIZE K/M/G  Absolute size free/used/available when critical\n";
  print " -v             Show verbose output\n";
  print "\nexample:\n";
  print "check_mem.pl -C -f -w 20 -c .5\n";
  print "\tReturns 1 (WARNING) if less than 20% free memory.\n";
  print "\tReturns 2 (CRITICAL) if less than 0.5% free memory.\n";
  print "\tTakes caches into account.\n";
  print "check_mem.pl -u -w 80 -c 95\n";
  print "\tReturns 1 (WARNING) if more than 80% memory in use.\n";
  print "\tReturns 2 (CRITICAL) if more than 95% memory in use.\n";
  print "check_mem.pl -C -f -w 2G -c 500M\n";
  print "\tReturns 1 (WARNING) if less than 2G free memory.\n";
  print "\tReturns 2 (CRITICAL) if less than 500M free memory.\n";
  print "\tTakes caches into account.\n";
  print "\nCopyright (C) 2000 Dan Larsson <dl\@tyfon.net>\n";
  print "check_mem.pl comes with absolutely NO WARRANTY either implied or explicit\n";
  print "This program is licensed under the terms of the\n";
  print "MIT License (check source code for details)\n";
  exit $exit_codes{'UNKNOWN'};
}

sub get_memory_info {
    my $used_memory_kb  = 0;
    my $free_memory_kb  = 0;
    my $total_memory_kb = 0;
    my $caches_kb       = 0;
    my $hugepages_nr    = 0;
    my $hugepages_size  = 0;
    my $hugepages_kb    = 0;
    my $available_memory_kb = 0;

    my $uname;
    if ( -e '/usr/bin/uname') {
        $uname = `/usr/bin/uname -a`;
    }
    elsif ( -e '/bin/uname') {
        $uname = `/bin/uname -a`;
    }
    else {
        die "Unable to find uname in /usr/bin or /bin!\n";
    }
    print "uname returns $uname" if ($opt_v);
    if ( $uname =~ /Linux/ ) {
        my @meminfo = `/bin/cat /proc/meminfo`;
        foreach (@meminfo) {
            chomp;
            if (/^Mem(Total|Free):\s+(\d+) kB/) {
                my $counter_name = $1;
                if ($counter_name eq 'Free') {
                    $free_memory_kb = $2;
                }
                elsif ($counter_name eq 'Total') {
                    $total_memory_kb = $2;
                }
            }
            elsif (/^(Buffers|Cached|SReclaimable):\s+(\d+) kB/) {
                $caches_kb += $2;
            }
            elsif (/^Shmem:\s+(\d+) kB/) {
                $caches_kb -= $1;
            }
            elsif (/^MemAvailable:\s+(\d+) kB/) {
                $available_memory_kb = $1;
            }
            # These variables will most likely be overwritten once we look into
            # /sys/kernel/mm/hugepages, unless we are running on linux <2.6.27
            # and have to rely on them
            elsif (/^HugePages_Total:\s+(\d+)/) {
                $hugepages_nr = $1;
            }
            elsif (/^Hugepagesize:\s+(\d+) kB/) {
                $hugepages_size = $1;
            }
        }
        $hugepages_kb = $hugepages_nr * $hugepages_size;
        $used_memory_kb = $total_memory_kb - $free_memory_kb;

        # Read hugepages info from the newer sysfs interface if available
        my $hugepages_sysfs_dir = '/sys/kernel/mm/hugepages';
        if ( -d $hugepages_sysfs_dir ) {
            # Reset what we read from /proc/meminfo
            $hugepages_kb = 0;
            opendir(my $dh, $hugepages_sysfs_dir)
                || die "Can't open $hugepages_sysfs_dir: $!";
            while (my $entry = readdir $dh) {
                if ($entry =~ /^hugepages-(\d+)kB/) {
                    $hugepages_size = $1;
                    my $hugepages_nr_file = "$hugepages_sysfs_dir/$entry/nr_hugepages";
                    open(my $fh, '<', $hugepages_nr_file)
                        || die "Can't open $hugepages_nr_file for reading: $!";
                    $hugepages_nr = <$fh>;
                    close($fh);
                    $hugepages_kb += $hugepages_nr * $hugepages_size;
                }
            }
            closedir($dh);
        }
    }
    elsif ( $uname =~ /HP-UX/ ) {
      # HP-UX, thanks to Christoph Fürstaller
      my @meminfo = `/usr/bin/sudo /usr/local/bin/kmeminfo`;
      foreach (@meminfo) {
        chomp;
        if (/^Physical memory\s\s+=\s+(\d+)\s+(\d+.\d)g/) {
            $total_memory_kb = ($2 * 1024 * 1024);
        }
        elsif (/^Free memory\s\s+=\s+(\d+)\s+(\d+.\d)g/) {
            $free_memory_kb = ($2 * 1024 * 1024);
        }
      }
     $used_memory_kb = $total_memory_kb - $free_memory_kb;
    }
    elsif ( $uname =~ /FreeBSD/ ) {
      # The FreeBSD case. 2013-03-19 www.claudiokuenzler.com
      # free mem = Inactive*Page Size + Cache*Page Size + Free*Page Size
      my $pagesize = `sysctl vm.stats.vm.v_page_size`;
      $pagesize =~ s/[^0-9]//g;
      my $mem_inactive = 0;
      my $mem_cache = 0;
      my $mem_free = 0;
      my $mem_total = 0;
      my $free_memory = 0;
        my @meminfo = `/sbin/sysctl vm.stats.vm`;
        foreach (@meminfo) {
            chomp;
            if (/^vm.stats.vm.v_inactive_count:\s+(\d+)/) {
            $mem_inactive = ($1 * $pagesize);
            }
            elsif (/^vm.stats.vm.v_cache_count:\s+(\d+)/) {
            $mem_cache = ($1 * $pagesize);
            }
            elsif (/^vm.stats.vm.v_free_count:\s+(\d+)/) {
            $mem_free = ($1 * $pagesize);
            }
            elsif (/^vm.stats.vm.v_page_count:\s+(\d+)/) {
            $mem_total = ($1 * $pagesize);
            }
        }
        $free_memory = $mem_inactive + $mem_cache + $mem_free;
        $free_memory_kb = ( $free_memory / 1024);
        $total_memory_kb = ( $mem_total / 1024);
        $used_memory_kb = $total_memory_kb - $free_memory_kb;
        $caches_kb = ($mem_cache / 1024);
    }
    elsif ( $uname =~ /joyent/ ) {
      # The SmartOS case. 2014-01-10 www.claudiokuenzler.com
      # free mem = pagesfree * pagesize
      my $pagesize = `pagesize`;
      my $phys_pages = `kstat -p unix:0:system_pages:pagestotal | awk '{print \$NF}'`;
      my $free_pages = `kstat -p unix:0:system_pages:pagesfree | awk '{print \$NF}'`;
      my $arc_size = `kstat -p zfs:0:arcstats:size | awk '{print \$NF}'`;
      my $arc_size_kb = $arc_size / 1024;

      print "Pagesize is $pagesize" if ($opt_v);
      print "Total pages is $phys_pages" if ($opt_v);
      print "Free pages is $free_pages" if ($opt_v);
      print "Arc size is $arc_size" if ($opt_v);

      $caches_kb += $arc_size_kb;

      $total_memory_kb = $phys_pages * $pagesize / 1024;
      $free_memory_kb = $free_pages * $pagesize / 1024;
      $used_memory_kb = $total_memory_kb - $free_memory_kb;
    }
    elsif ( $uname =~ /SunOS/ ) {
        eval "use Sun::Solaris::Kstat";
        if ($@) { #Kstat not available
            if ($opt_C) {
                print "You can't report on Solaris caches without Sun::Solaris::Kstat available!\n";
                exit $exit_codes{UNKNOWN};
            }
            my @vmstat = `/usr/bin/vmstat 1 2`;
            my $line;
            foreach (@vmstat) {
              chomp;
              $line = $_;
            }
            $free_memory_kb = (split(/ /,$line))[5] / 1024;
            my @prtconf = `/usr/sbin/prtconf`;
            foreach (@prtconf) {
                if (/^Memory size: (\d+) Megabytes/) {
                    $total_memory_kb = $1 * 1024;
                }
            }
            $used_memory_kb = $total_memory_kb - $free_memory_kb;

        }
        else { # We have kstat
            my $kstat = Sun::Solaris::Kstat->new();
            my $phys_pages = ${kstat}->{unix}->{0}->{system_pages}->{physmem};
            my $free_pages = ${kstat}->{unix}->{0}->{system_pages}->{freemem};
            # We probably should account for UFS caching here, but it's unclear
            # to me how to determine UFS's cache size.  There's inode_cache,
            # and maybe the physmem variable in the system_pages module??
            # In the real world, it looks to be so small as not to really matter,
            # so we don't grab it.  If someone can give me code that does this,
            # I'd be glad to put it in.
            my $arc_size = (exists ${kstat}->{zfs} && ${kstat}->{zfs}->{0}->{arcstats}->{size}) ?
                 ${kstat}->{zfs}->{0}->{arcstats}->{size} / 1024
                 : 0;
            $caches_kb += $arc_size;
            my $pagesize = `pagesize`;

            $total_memory_kb = $phys_pages * $pagesize / 1024;
            $free_memory_kb = $free_pages * $pagesize / 1024;
            $used_memory_kb = $total_memory_kb - $free_memory_kb;
        }
    }
    elsif ( $uname =~ /Darwin/ ) {
        $total_memory_kb = (split(/ /,`/usr/sbin/sysctl hw.memsize`))[1]/1024;
        my $pagesize     = (split(/ /,`/usr/sbin/sysctl hw.pagesize`))[1];
        $caches_kb       = 0;
        my @vm_stat = `/usr/bin/vm_stat`;
        foreach (@vm_stat) {
            chomp;
            if (/^(Pages free):\s+(\d+)\.$/) {
                $free_memory_kb = $2*$pagesize/1024;
            }
            # 'caching' concept works different on MACH
            # this should be a reasonable approximation
            elsif (/^Pages (inactive|purgable):\s+(\d+).$/) {
                $caches_kb += $2*$pagesize/1024;
            }
        }
        $used_memory_kb = $total_memory_kb - $free_memory_kb;
    }
    elsif ( $uname =~ /AIX/ ) {
        my @meminfo = `/usr/bin/vmstat -vh`;
        foreach (@meminfo) {
            chomp;
            if (/^\s*([0-9.]+)\s+(.*)/) {
                my $counter_name = $2;
                if ($counter_name eq 'memory pages') {
                    $total_memory_kb = $1*4;
                }
                if ($counter_name eq 'free pages') {
                    $free_memory_kb = $1*4;
                }
                if ($counter_name eq 'file pages') {
                    $caches_kb = $1*4;
                }
                if ($counter_name eq 'Number of 4k page frames loaned') {
                    $free_memory_kb += $1*4;
                }
            }
        }
        $used_memory_kb = $total_memory_kb - $free_memory_kb;
    }
    else {
        if ($opt_C) {
            print "You can't report on $uname caches!\n";
            exit $exit_codes{UNKNOWN};
        }
        my $command_line = `vmstat | tail -1 | awk '{print \$4,\$5}'`;
        chomp $command_line;
        my @memlist      = split(/ /, $command_line);

        # Define the calculating scalars
        $used_memory_kb  = $memlist[0]/1024;
        $free_memory_kb = $memlist[1]/1024;
        $total_memory_kb = $used_memory_kb + $free_memory_kb;
    }
    return ($free_memory_kb/1000,$used_memory_kb/1000,$caches_kb/1000,$available_memory_kb/1000,$hugepages_kb/1000);
}

sub parameterize_thresholds{
  my $limit;
  my $is_abs = 0;
  my ($opt, $level, $total) = @_;

  if ($opt =~ /^((\d+)\s*([KMG]))$/) {
      # SIZE INTEGER K|M|G
      $is_abs = 1;
      $limit = $2;
      $3 eq 'K' ? $limit *= 1 :
      $3 eq 'M' ? $limit *= 1024 :
      $3 eq 'G' ? $limit *= 1024 * 1024 : die ;
      if ($limit > $total) {
          print "*** $level limit: $limit level is bigger than the total of the system memory: $total";
          &usage;
      }
  }
  elsif ($opt =~ /^(?=.)(([0-9]*)(\.([0-9]+))?)$/) {
      # PERCENTAGE (1, 95, 0.5)
      if ($1 > 100) {
          print "*** $level percentage > 100%!\n";
          &usage;
      }
      $limit = int(${total} * $1 / 100);
  }
  else {
      print "*** $level value not recognized!\n";
      &usage;
  }
  return ($limit, $is_abs);
}

sub init {
    # Get the options
    if ($#ARGV le 0) {
      &usage;
    }
    else {
      getopts('c:fuaChvw:');
    }

    # Shortcircuit the switches
    if (! defined $opt_w or ! defined $opt_c) {
      print "*** You must define WARN and CRITICAL levels!\n";
      &usage;
    }
    elsif (!$opt_f and !$opt_u and !$opt_a) {
      print "*** You must select to monitor USED, FREE or AVAILABLE memory!\n";
      &usage;
    }
    elsif ($opt_f and $opt_u or $opt_f and $opt_a or $opt_u and $opt_a) {
      print "*** You must select to monitor either USED, FREE or AVAILABLE memory!\n";
      &usage;
    }
    elsif ($opt_w !~ /^((\d+)\s*([KMG])|(?=.)(([0-9]*)(\.([0-9]+))?))$/) {
      # SIZE INTEGER K|M|G OR PERCENTAGE INTEGER|FLOAT
      print "*** WARN level must be defined as PERCENTAGE (1 - 99) or SIZE K/M/G!\n";
      &usage;
    }
    elsif ($opt_c !~ /^((\d+)\s*([KMG])|(?=.)(([0-9]*)(\.([0-9]+))?))$/) {
      # SIZE INTEGER K|M|G OR PERCENTAGE INTEGER|FLOAT
      print "*** CRITICAL level must be defined as PERCENTAGE (1 - 99) or SIZE K/M/G!\n";
      &usage;
    }
}

sub finish {
    my ($msg,$state) = @_;
    print "$msg\n";
    exit $state;
}
