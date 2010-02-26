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

package sites::reddit;

use warnings;
use strict;

use HTML::TreeBuilder;
use HTML::Entities;
use Time::ParseDate;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for reddit.com
#
# This plugin is a part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

use constant POSTS_PER_PAGE => 25;

#
# site_name
#
# returns short name for the site
#
sub site_name { 'reddit' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    my $offset = POSTS_PER_PAGE * ($page - 1);

    my $url;
    if (exists $self->{vars}->{subreddit}) {
        $url = "http://$self->{vars}->{subreddit}.reddit.com/"
    }
    else {
        $url = "http://reddit.com/";
    }

    if ($page == 1) {
        return $url
    }

    # we can't just add $url .= "?count=$offset"; any longer
    # because reddit has added some funny 'after=' id, we need to
    # go through N-1 pages to get a link to N-th page.

    my $reddit_url = $url;
    my $contents;
    for my $p (1..$page) {
        if ($p == 1) {
            $url = $reddit_url;
        }
        else {
            my $tree = HTML::TreeBuilder->new;
            $tree->parse($contents);
            $tree->eof;

            my $menu = $tree->look_down(_tag => 'p', class => 'menu');
            return undef unless $menu;

            my $next_a = $menu->look_down(_tag => 'a', sub { $_[0]->as_text =~ /next/ });
            return undef unless $next_a;

            $url = $reddit_url . $next_a->attr('href');

            $tree->delete;
        }
        my $response = $self->ua_get_page($url);
        $contents = $response->decoded_content;
    }

    return $url;
}

#
# get_posts
#
sub get_posts {
    my ($self, $content) = @_;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
    $tree->eof;

    my (@posts, %post_entry);
    my @trs = $tree->look_down("_tag" => "tr", "id" => qr{^thingrow_t3});
    foreach my $tr (@trs) {
        my $entry_div = $tr->look_down(_tag => 'div', id=>qr{^entry_t3});
        next unless $entry_div;

        my @info_trs = $entry_div->look_down(_tag => 'tr');
        next unless @info_trs == 2;

        my $title_tr  = $info_trs[0];
        my $status_tr = $info_trs[1];

        my $title_a = $title_tr->look_down(_tag => 'a', 'id' => qr{^title_t3});
        next unless $title_a;

        my $score_span = $status_tr->look_down(_tag => 'span', id => qr{^score_t3});
        next unless $score_span;

        my $post_time_info = $score_span->right;
        next unless $post_time_info;

        my $user_a = $status_tr->look_down(_tag => 'a', sub { $_[0]->attr('href') =~ m#/user/(.+)/# });
        next unless $user_a;

        my %post_entry;

        if ($user_a->attr('href') =~ m#/user/(.+)/#) {
            $post_entry{user} = $1;
        }

        if ($score_span->attr('id') =~ /score_t3_(.+)/) {
            $post_entry{id} = $1;
        }

        my $title = decode_entities($title_a->as_text);
        $title =~ s/^\s+|\s+$//g;
        $title =~ s/^\[(humor|science|programming|politics)\]\s+//g;
        $post_entry{title} = $title;

        my $url = $title_a->attr('href');
        $post_entry{url} = $url;

        my $score_text = $score_span->as_text;
        if ($score_text =~ /(\d+) points/) {
            $post_entry{score} = $1;
        }
        else {
            $post_entry{score} = 1;
        }

        print $post_time_info, "\n";
        if ($post_time_info =~ /posted (.+) by/) {
            my $unix_time  = parsedate($1);
            my $human_time = strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time);

            $post_entry{unix_time}  = $unix_time;
            $post_entry{human_time} = $human_time;
        }

        push @posts,  { %post_entry };
    }

    $tree->delete;
    return @posts;    
}


1;
