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

package sites::scraper;

use warnings;
use strict;

#
# Base class for all the scraper plugins.
#
# This module is part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#


use LWP::UserAgent;

binmode STDOUT, ':utf8';

sub new {
    my ($this, %params) = @_;
    my $class = ref($this) || $this;

    my %self = %params;
    $self{ua} = LWP::UserAgent->new(
        agent   => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) Gecko/20070515 Firefox/2.0.0.4',
        timeout => 10
    );
    $self{ua}->default_headers->push_header('Accept-Language' => 'en-us,en;q=0.5');

    bless \%self, $class;
}

#
# scrape_verbose
#
# scrapes site and prints out posts
#
sub scrape_verbose {
    my $self = shift;

    $self->scraper(sub {
            my $post = shift;
            my $had_print = 0;
            foreach my $key (sort keys %$post) {
                next unless defined $post->{$key};
                my $val = $post->{$key};
                $val =~ s/^\s+|\s+$//g;
                unless (length $val) {
                    $val = "(empty)";
                }
                print "$key: $val\n";
                $had_print++;
            }
            if ($had_print) {
                print "site: ", $self->site_name, "\n";
            }
            print "\n";
    });
}

#
# scrape
#
# scrapes site and returns an array of all posts
#
sub scrape {
    my $self = shift;

    my @posts;
    $self->scraper(sub {
            my $post = shift;
            push @posts, $post;
    });

    return @posts;
}

#
# scraper
#
# scrapes site and applies action_sub on each post
#
sub scraper {
    my $self = shift;
    my $action_sub = shift;
    my $pages = $self->{pages} || 1;

    for my $page (1..$pages) {
        my $page_url = $self->get_page_url($page);
        unless ($page_url) {
            print STDERR "Failed getting page $page URL:\n"; # TODO: add basic error state
            return;
        }
        my $response = $self->ua_get_page($page_url);
        unless ($response->is_success) {
            print STDERR "Failed getting page '$page_url': ", $response->status_line, "\n";
            return;
        }
        my @posts = $self->get_posts($response->decoded_content);
        my @filtered_posts = $self->filter_posts(@posts);

        foreach (@filtered_posts) {
            $action_sub->($_);
        }
    }
}

#
# filter_posts
#
# filters out only posts matching a pattern
#
sub filter_posts {
    my ($self, @posts) = @_;

    unless (exists $self->{patterns}) {
        if (defined $self->{pattern_file}) {
            $self->{patterns} = { $self->parse_pattern_file($self->{pattern_file}) };
        }
    }

    my @bad_urls;
    if (exists $self->{vars}->{bad_urls}) {
        @bad_urls = split ',\s*', $self->{vars}->{bad_urls};
    }

    my @filtered_posts;
    POST:
    foreach my $post (@posts) { # don't care about algorithmic complexity
        if (@bad_urls) {
            foreach my $url (@bad_urls) {
                if ($post->{url} =~ qr/\Q$url/i) {
                    next POST;
                }
            }
        }

        if (exists $self->{patterns}) {
            foreach my $pattern_type (keys %{$self->{patterns}}) {
                # 'perl' pattern type contains filter predicates
                next unless exists $post->{$pattern_type} or $pattern_type eq "perl";
                foreach my $pattern (@{$self->{patterns}->{$pattern_type}}) {
                    if ($pattern_type eq "perl") {
                        if ($pattern->($post)) {
                            push @filtered_posts, $post;
                        }
                    }
                    elsif ($post->{$pattern_type} =~ /$pattern/i) {
                        push @filtered_posts, $post;
                        next POST;
                    }
                }
            }
        }
        else {
            push @filtered_posts, $post
        }
    }

    return @filtered_posts;
}

#
# ua_get_page
#
# given an url, function http gets the page and returns HTTP::Response object;
#
sub ua_get_page {
    my ($self, $url) = @_;
    return $self->{ua}->get($url);
}

#
# parse_pattern_file
#
# parses the pattern file and returns a hash data structure
# which each plugin understands
#
sub parse_pattern_file {
    my ($self, $file) = @_;
    my $contents = do { local (@ARGV, $/) = $file; <> };

    return $self->parse_patterns($contents);
}

#
# parse_patterns
#
# given a string of patterns, parses it and returns a hash data
# structure such that it can be easily used by the parser
#
sub parse_patterns {
    my ($self, $patterns) = @_;
    my %ret_data;

    # patterns might have perl code in them, extract perl code and
    # remove them from the $patterns string.
    #
    while ($patterns =~ s#perl:\s*(sub {.*?[\r\n]})##s) {
        push @{$ret_data{perl}}, eval "$1";
        if ($@) {
            die "Filter predicate failed eval()-ing:\n$1\n";
        }
    }

    # Parse the rest of the file line by line
    #
    my @lines = split /[\r\n]+/, $patterns;
    foreach (@lines) {
        next if /^#/ || !length;
        if (/(url|title|desc):\s*(.+)/) {
            push @{$ret_data{$1}}, qr{$2}i;
        }
        else {
            push @{$ret_data{title}}, qr{$_}i;
            push @{$ret_data{desc}}, qr{$_}i;
        }
    }
    return %ret_data;
}

1;
