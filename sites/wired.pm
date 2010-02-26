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

package sites::wired;

use warnings;
use strict;

use XML::Simple;
use Date::Parse;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for wired.com
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
sub site_name { 'wired' }

#
# get_page_url
#
# given a page number, returns url of that page
#
# sections can be found at http://www.wired.com/services/rss/
# for example 'Wired Wireless' section would be 'gadgets/wireless' because
# link to it is 'http://feeds.wired.com/wired/gadgets/wireless'
#
# basically section is everything after 'http://feeds.wired.com/wired/' url
#
sub get_page_url {
    my ($self, $page) = @_;

    my $url = "http://feeds.wired.com/wired";
    if (exists $self->{vars}->{section}) {
        $url .= "/" . $self->{vars}->{section};
    }
    else {
        $url.= "/index";
    }

    return $url
}

#
# get_posts
#
sub get_posts {
    my ($self, $xml) = @_;
    my $stories = XMLin($xml, KeyAttr => []);

    my @ret_stories;
    foreach (@{$stories->{channel}->{item}}) {
        my $unix_time  = str2time($_->{'dc:date'});
        my $human_time = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time);
        push @ret_stories, {
            url        => exists $_->{'feedburner:origLink'} ?
                                 $_->{'feedburner:origLink'} : $_->{link},
            title      => $_->{title},
            user       => $_->{'dc:creator'},
            unix_time  => $unix_time,
            human_time => $human_time
        }
    }
    return @ret_stories;
}

1;
