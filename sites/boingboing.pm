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

package sites::boingboing;

use warnings;
use strict;

use HTML::TreeBuilder;
use Date::Parse;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for boingboing.net
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
sub site_name { 'boingboing' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;
    
    if ($page > 1) { return } # at the moment return news just for the 1st page

    my $url = "http://www.boingboing.net";

    return $url;
}

#
# get_posts
#
# subroutine takes html content of a boingboing page and extracts post information
# from each of the articles
#
sub get_posts {
    my ($self, $html) = @_;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);
    $tree->eof;

    my @ret_stories;
    my @entries = $tree->look_down(_tag => 'div', id => qr/entry-\d+/);
    foreach my $entry (@entries) {
        my $header  = $entry->look_down(_tag => 'h3',  class => 'entry-header');
        my $meta    = $entry->look_down(_tag => 'div', class => 'entry-metadata');
        my $content = $entry->look_down(_tag => 'div', class => 'entry-content');
        next unless $header && $meta && $content;

        next unless ($content->look_down(_tag => 'img')); # only posts with images

        my $title_a = $header->look_down(_tag => 'a');
        next unless $title_a;

        my $title = $title_a->as_text;
        my $url   = $title_a->attr('href');

        my ($user, $unix_time, $human_time);
        if ($meta->as_text =~ /Posted by (.+?),/) {
            $user = $1;
        }
        if ($meta->as_text =~ /((\w+) (\d+), (\d{4}) (\d+):(\d+) (AM|PM))/) {
            $unix_time  = str2time($1);
            $human_time = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time);
        }

        push @ret_stories, {
            title      => $title,
            url        => $url,
            user       => $user,
            unix_time  => $unix_time,
            human_time => $human_time
        };
    }
    $tree->delete;

    return @ret_stories;
}

1;
