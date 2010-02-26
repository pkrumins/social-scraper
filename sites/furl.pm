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

package sites::furl;

use warnings;
use strict;

use XML::Simple;
use Date::Parse;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for furl.com
#
# This plugin is a part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

#
# site_name
#
# returns short name for the site
#
sub site_name { 'furl' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    my $url = 'http://furl.net/members/rssPopular.xml?';
    if (exists $self->{vars}->{days}) {
        $url .= "days=" . $self->{vars}->{days};
    }
    else {
        $url .= "days=6";
    }

    if (exists $self->{vars}->{topic}) {
        $url .= "&topic=" . $self->{vars}->{topic};
    }

    return $url;
    
}

#
# get_posts
#
sub get_posts {
    my ($self, $xml) = @_;
    my $stories = XMLin($xml, KeyAttr => [], ForceArray => ['item']);

    my @ret_stories;
    foreach (@{$stories->{channel}->{item}}) {
        my $unix_time  = str2time($_->{pubDate});
        my $human_time = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time);

        my $story = {
            url              => $_->{link},
            title            => $_->{title},
            unix_time        => $unix_time,
            human_time       => $human_time
        };
        push @ret_stories, $story;
    }
    return @ret_stories;
}

1;
