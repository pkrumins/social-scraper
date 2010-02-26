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

package sites::delicious;

use warnings;
use strict;

use Date::Parse;
use XML::Simple;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for del.icio.us
#
# This plugin is part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

#
# site_name
#
# returns short name for the site
#
sub site_name { 'delicious' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    my $service_url = "http://del.icio.us/rss";

    if (exists $self->{vars}->{popular}) {
        $service_url .= "/popular";
    }
    elsif (exists $self->{vars}->{recent}) {
        $service_url .= "/recent";
    }
    elsif (exists $self->{vars}->{user}) {
        $service_url .= "/$self->{vars}->{user}";
    }

    if (exists $self->{vars}->{tag}) {
        $service_url .= "/$self->{vars}->{tag}";
    }

    return $service_url;
}

#
# get_posts
#
# subroutine takes XML content of del.icio.us bookmarks and returns an array
# of hashes containing information about each bookmark.
#
sub get_posts {
    my ($self, $xml) = @_;

    my $stories = XMLin($xml, KeyAttr => [], ForceArray => ['item']);

    my @ret_stories;
    foreach (@{$stories->{item}}) {
        my $time = str2time($_->{'dc:date'});

        my $story = {
            title       => $_->{'title'},
            url         => $_->{'link'},
            unix_time   => $time,
            human_time  => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime $time),
            user        => $_->{'dc:creator'}
        };
        push @ret_stories, $story;
    }
    return @ret_stories;
}

1;
