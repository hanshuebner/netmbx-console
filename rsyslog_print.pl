#!/usr/bin/perl -w

use POSIX qw(strftime);

use strict;

my $FEED_TIMEOUT = 5;

sub wide_font {
    return "\eM\0";
}

sub narrow_font {
    return "\eM\1";
}

sub cut_paper {
    return "\x1dV\0";
}

open(LOG, ">>/tmp/log");
select(LOG); $| = 1; select(STDOUT);

open(STDOUT, ">/dev/usb/lp0") or die;
$| = 1;
my $old_date = "";
my $old_host = "";
while (<>) {
    print LOG;
    m/....-..-..T..:..:..(?:\.\d+)?\+..:.. (\S+) (.*)/;
    my ($host, $message) = ($1, $2);

    $host =~ s/\.netmbx\.org$//;

    my $date = strftime "%Y-%m-%d", localtime;
    my $time = strftime "%H:%M:%S", localtime;

    if ($date ne $old_date) {
        print "\n\n\n\n\n", cut_paper();
        $old_date = $date;
    }
        
    if ($host eq "symbrick" and $message =~ /^vax /) {
        $message =~ s/vax //;
        $message =~ s/#007//g;
        $host = "vax";
    }

    if ($host eq "cisco") {
        $message =~ s/^\d+: ..:..:..: //;
    }

    if ($host eq "escpos" && $message =~ /^xot: /) {
        $host = "inbound-x25";
        $message =~ s/xot: //;
    }

    if ($host ne $old_host) {
        print wide_font(), "\n--- $date $time $host\n\n";
        $old_host = $host;
    }

    print narrow_font(), $message, "\n";

    my $rin = '';
    vec($rin, fileno(STDIN), 1) = 1;

    unless (select($rin, undef, undef, $FEED_TIMEOUT)) {
        print "\n\n\n\n\n\n";
    }
}
