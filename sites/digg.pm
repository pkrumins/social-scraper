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

package sites::digg;

use warnings;
use strict;

use XML::Simple;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for digg.com
#
# This plugin is part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

use constant POSTS_PER_PAGE => 15;
use constant DIGG_APPKEY => 'http://picurls.com';

#
# site_name
#
# returns short name for the site
#
sub site_name { 'digg' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    my $offset = POSTS_PER_PAGE * ($page - 1);

    my $service_url = "http://services.digg.com/stories";

    if (exists $self->{vars}->{container}) {
        $service_url .= "/container/$self->{vars}->{container}";
    }
    elsif (exists $self->{vars}->{topic}) {
        $service_url .= "/topic/$self->{vars}->{topic}";
    }

    if (exists $self->{vars}->{popular}) {
        $service_url .= "/popular";
    }

    $service_url   .= "?appkey=" . DIGG_APPKEY;
    $service_url   .= "&offset=" . $offset;
    $service_url   .= "&count="  . POSTS_PER_PAGE;

    return $service_url;
}

#
# get_posts
#
# taken from digpicz.com website generator:
# http://www.catonmat.net/blog/designing-digg-picture-website
#
# subroutine takes XML content of digg stories and returns an array
# of hashes containing information about each story on the page.
#
sub get_posts {
    my ($self, $xml) = @_;
    my $stories = XMLin($xml, KeyAttr => [], ForceArray => ['story']);

    my @ret_stories;
    foreach (@{$stories->{story}}) {
        my $story = {
            topic_short_name => $_->{topic}->{short_name},
            topic_name       => $_->{topic}->{name},
            url              => $_->{link},
            status           => $_->{status},
            container_short_name => $_->{container}->{short_name},
            container_name       => $_->{container}->{name},
            human_time       => strftime("%Y-%m-%d %H:%M:%S", localtime $_->{submit_date}),
            unix_time        => $_->{submit_date},
            description      => $_->{description},
            comments         => $_->{comments},
            score            => $_->{diggs},
            user_icon        => $_->{user}->{icon},
            user_registrered => $_->{user}->{registered},
            user             => $_->{user}->{name},
            user_profileviews => $_->{user}->{profileviews},
            id               => $_->{id},
            title            => $_->{title}
        };
        push @ret_stories, $story;
    }
    return @ret_stories;
}

1;
