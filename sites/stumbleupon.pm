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

package sites::stumbleupon;

use warnings;
use strict;

use HTML::TreeBuilder;
use Time::ParseDate;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for stumbleupon.com
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
sub site_name { 'stumbleupon' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    my $url = "http://www.stumbleupon.com";
    if (exists $self->{vars}->{tag}) {
        $url .= "/tag/$self->{vars}->{tag}/";
    }

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

    if (exists $self->{vars}->{tag}) {
        return $self->get_posts_tag($tree);
    }
    else {
        return $self->get_posts_front_page($tree);
    }

}

sub get_posts_tag {
    my ($self, $tree) = @_;

    my $blogs = $tree->look_down(_tag => 'div', class => 'listBlogs');
    return unless $blogs;

    return $self->extract_posts($blogs);
}

sub get_posts_front_page {
    my ($self, $tree) = @_;

    my $buzz = $tree->look_down(_tag => 'div', id => 'listBuzz');
    return unless $buzz;

    return $self->extract_posts($buzz);
}

sub extract_posts {
    my ($self, $tree) = @_;

    my @ret_stories;
    my @dls = $tree->look_down(_tag => 'dl');
    foreach my $dl (@dls) {
        my $a = $dl->look_down(_tag => 'a', sub { not $_[0]->look_down(_tag => 'img') });
        next unless $a;

        my ($url, $title) = ($a->attr('href'), $a->as_text);

        my ($desc, $human_time, $unix_time);
        my @dds = $dl->look_down(_tag => 'dd');
        if (exists $dds[1]) {
            my $rated_text;
            eval {
                $rated_text = $dds[1]->look_down(_tag => 'a')->right;
            };
            unless ($@) {
                if ($rated_text =~ /(?:rated|tagged) (.+)\s+$/) {
                    $unix_time  = parsedate($1);
                    $human_time = strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time);
                }
            }
        }

        if (exists $dds[2]) {
            $desc = $dds[2]->as_text;
        }

        push @ret_stories, {
            url        => $url,
            title      => $title,
            desc       => $desc,
            unix_time  => $unix_time,
            human_time => $human_time
        }
    }
    return @ret_stories;
}

1;
