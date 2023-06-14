#!/usr/bin/perl

use strict;
use warnings;
use Socket;
use Sys::Syslog qw(:DEFAULT setlogsock);
use LWP::UserAgent;
use JSON;

# Initialize the system logger
setlogsock('unix');
openlog("xot", "ndelay", "local4");

# Loop through each line of the log file
while (my $line = <>) {
    chomp $line;

    # Extract relevant fields from the log entry
    if ($line =~ /SRC=(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*DPT=1998 /) {
        my $src_address = $1;

        # Retrieve the hostname associated with the source IP address
        my $hostname = get_hostname($src_address);

        # Retrieve geolocation information for the IP address
        my $geo_info = get_geolocation($src_address);

        # Extract relevant details from the geolocation response
        my $country = $geo_info->{country} || "Unknown";
        my $city    = $geo_info->{city}    || "Unknown";
        my $isp     = $geo_info->{isp}    || "Unknown";

        # Construct the log message
        my $log_message = "$src_address ($hostname) - $country, $city ($isp)";

        # Send the log message to the system logger
        syslog('info', $log_message);
    }
}

# Close the system logger
closelog();

# Function to get the hostname associated with an IP address
sub get_hostname {
    my ($ip_address) = @_;

    # Use any method or tool to retrieve the hostname based on the IP address
    # Here, we're using the `gethostbyaddr` function from Socket module
    my $hostname = gethostbyaddr(inet_aton($ip_address), AF_INET) || "Unknown";

    return $hostname;
}

# Function to fetch geolocation information for an IP address
sub get_geolocation {
    my ($ip_address) = @_;

    my $url = "http://ip-api.com/json/$ip_address";

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);

    if ($response->is_success) {
        my $content = $response->decoded_content;
        my $geo_info = decode_json($content);

        return $geo_info;
    } else {
        warn "Failed to fetch geolocation information for $ip_address: " . $response->status_line;
        return {};
    }
}
