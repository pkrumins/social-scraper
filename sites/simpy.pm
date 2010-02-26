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

package sites::simpy;

use warnings;
use strict;

use HTML::TreeBuilder;
use Date::Parse;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for simpy.com
#
# This plugin is a part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

use constant POSTS_PER_PAGE => 20;

#
# site_name
#
# returns short name for the site
#
sub site_name { 'simpy' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    return undef unless exists $self->{vars}->{tag};

    my $url = "http://www.simpy.com/links/tag";
    $url .= "/$self->{vars}->{tag}";
    $url .= "/p=" . ($page - 1) * POSTS_PER_PAGE . ',' . POSTS_PER_PAGE;

    return $url;
}

#
# get_posts
#
sub get_posts {
    my ($self, $html) = @_;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);
    $tree->eof;

    my @ret_posts;

    my @blocks = $tree->look_down(_tag => 'div', class => 'syLinkBlock');
    foreach my $block (@blocks) {
        my $title_div = $block->look_down(_tag => 'div', class => 'syLinkTitle');
        my $meta_div  = $block->look_down(_tag => 'div', class => 'syLinkMeta');
        next unless ($title_div && $meta_div);

        my $title_a = $title_div->look_down(_tag => 'a', class => 'mcsp');
        next unless $title_a;

        my ($title, $url) = ($title_a->as_text, $title_a->attr('href'));

        my ($user, $unix_time, $human_time);
        my $user_a = $meta_div->look_down(_tag => 'a', class => 'syUsername');
        if ($user_a) {
            $user = $user_a->as_text;
        }
        my $date_span = $meta_div->look_down(_tag => 'span', class => 'syLinkTime');
        if ($date_span) {
            $human_time = $date_span->as_text;
            $unix_time  = str2time($human_time);
        }

        push @ret_posts, {
            title      => $title,
            url        => $url,
            user       => $user,
            human_time => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time),
            unix_time  => $unix_time
        }
    }
    return @ret_posts;
}
1;
