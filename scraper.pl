#!/usr/bin/perl
#
# Copyright (C) 2007 Peteris Krumins (peter@catonmat.net)
# http://www.catonmat.net  -  good coders code, great reuse
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use warnings;
use strict;

#
# This program scrapes given site(s) extracting posts matching
# given pattern(s)
#
# A new site can be added by writing a plugin for it.
#
# Patterns are specified as the last argument which should be
# path to the file containing the patterns.
#
# This program is a part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

use File::Find;

my %plugins = load_plugins();

unless (@ARGV) {
    usage();
    exit 1;
}

if ($ARGV[0] eq "--sites") {
    print_sites();
    exit 0;
}
elsif ($ARGV[0] eq "--help") {
    usage();
    exit 0;
}

my %sites;
my $pattern_file;
foreach my $idx (0 .. $#ARGV) {
    if ($idx == $#ARGV) { # last argument might be pattern file
        if (-r $ARGV[$idx]) {
            $pattern_file = $ARGV[$idx];
            last;
        }
    }

    my @parts = split ':\s*', $ARGV[$idx]; # site[:M][:{var1=val1; var2=val2}]
    my $site = $parts[0];

    if (@parts == 1) { # just the site specified
        push @{$sites{$site}}, { pages => 1 };
    }
    elsif (@parts == 2) { # either pages to scrape specified or args
        if ($parts[1] =~ /{\s*(.+)\s*}/) {
            my %vars = parse_vars($1);
            push @{$sites{$site}}, {
                pages => 1,
                vars  => \%vars
            };
        }
        elsif ($parts[1] =~ /^\d+$/) {
            push @{$sites{$site}}, { pages => $parts[1] };
        }
        else {
            print STDERR "Invalid argument: '$ARGV[$idx]'. Ignoring!\n";
        }
    }
    elsif (@parts == 3) { # pages and args
        my %site_entry;
        if ($parts[1] =~ /^\d+$/) {
            $site_entry{pages} = $parts[1];
        }
        else {
            print STDERR "Invalid argument: '$ARGV[$idx]'. Ignoring!\n";
            next;
        }

        if ($parts[2] =~ /{\s*(.+)\s*}/) {
            my %vars = parse_vars($1);
            $site_entry{vars} = \%vars;
            push @{$sites{$site}}, \%site_entry;
        }
        else {
            print STDERR "Invalid argument: '$ARGV[$idx]'. Ignoring!\n";
        }
    }
    else {
        print STDERR "Invalid argument: '$ARGV[$idx]'. Ignoring!\n";
    }
}

unless (keys %sites) {
    usage();
    exit 1;
}

foreach (keys %sites) { # check if all sites listed have a plugin
    unless (exists $plugins{$_}) {
        print "Plugin for '$_' does not exist!";
        exit 1;
    }
}

foreach my $site (keys %sites) {
    foreach my $entry (@{$sites{$site}}) {
        my $scraper = $plugins{$site}->new(
            pages => $entry->{pages},
            vars  => $entry->{vars} || {},
            pattern_file => $pattern_file
        );
        $scraper->scrape_verbose();
    }
}

#
# parse_vars
#
# parses a string in format 'var1=val1; var2=val2' and returns a hash with var => vals
#
sub parse_vars {
    my $varvals = shift;
    my @valvars = split '\s*;\s*', $varvals;
    my %rethash;
    foreach my $vv (@valvars) {
        my ($var, $val) = $vv =~ /(\w+)\s*=(.+)/;
        $val =~ s/^\s+|\s+$//g;
        $rethash{$var} = $val;
    }

    return %rethash;
}

#
# load_plugins
#
# loads the existing site plugins.
#
sub load_plugins {
    my @plugins;
    my %ret_plugs;
    find (sub { push @plugins, $_ if /\.pm$/ && !/scraper\.pm/}, 'sites');
    foreach my $p (@plugins) {
        $p = 'sites::' . $p;
        $p =~ s/\.pm$//;
        eval "require $p";
        unless ($@) {
            $ret_plugs{$p->site_name} = $p;
        }
        else {
            print "Failed loading $p: $@\n";
        }
    }
    return %ret_plugs;
}

#
# print_sites
#
# prints all loaded plugins for sites
#
sub print_sites {
    print "Available sites:\n";
    print join ' ', sort keys %plugins;
    print "\n";
}

#
# usage
#
# prints program's usage
#
sub usage {
    print "Program by Peteris Krumins (peter\@catonmat.net)\n";
    print "http://www.catonmat.net  -  good coders code, great reuse\n";
    print "\n";
    print "Usage: $0 <site[:M][:{var1=val1; var2=val2}]> ... [/path/to/pattern_file]\n";
    print "Crawls given sites extracting entries matching optional patterns in pattern_file\n";
    print "Optional argument M specifies how many pages to crawl, default 1\n";
    print "Arguments (variables) for plugins can be passed via an optional { }\n";
    print "\nor\n";
    print "Usage: $0 [--sites|--help]\n";
    print "Prints all installed site plugins (--sites), or prints this message (--help)\n";
    print "\n";
}

