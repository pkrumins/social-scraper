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

package sites::flickr;

use warnings;
use strict;

use XML::Simple;
use POSIX;

use base 'sites::scraper';

#
# scraper plugin for most interesting photos on flickr.com
#
# This plugin is a part of picurls.com website data miner.
# More about it at:
# http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one
#

use constant POSTS_PER_PAGE => 15;

use constant API_KEY => 'ee181137107a099f795278d353239db5';

#
# site_name
#
# returns short name for the site
#
sub site_name { 'flickr' }

#
# get_page_url
#
# given a page number, returns url of that page
#
sub get_page_url {
    my ($self, $page) = @_;

    # get just the interesting photos at the moment
    #
    my $url = 'http://api.flickr.com/services/rest/?method=flickr.interestingness.getList';
    $url .= '&api_key=' . API_KEY;
    $url .= '&per_page=' . POSTS_PER_PAGE;
    $url .= '&page=' . $page;

    return $url;
}

#
# get_posts
#
# subroutine takes XML content of flickr returned images and returns an array
# of hashes containing information about each image
#
sub get_posts {
    my ($self, $xml) = @_;

    my $stories = XMLin($xml, KeyAttr => [], ForceArray => ['photo']);

    my @ret_pics;
    if ($stories->{stat} eq "ok") {
        foreach (@{$stories->{photos}->{photo}}) {
            # get info of the photo by ID
            #
            my $info = $self->_get_photo_info($_);
            next unless $info;

            my $unix_time  = $info->{photo}->{dates}->{posted};
            my $human_time = strftime("%Y-%m-%d %H:%M:%S", localtime $unix_time);

            push @ret_pics, {
                title      => $_->{'title'},
                #url      => "http://farm$_->{farm}.static.flickr.com/$_->{server}/$_->{id}_$_->{secret}.jpg",
                url        => $info->{photo}->{urls}->{url}->{content},
                user       => $info->{photo}->{owner}->{username},
                unix_time  => $unix_time,
                human_time => $human_time
            };
        }
    }
    return @ret_pics;
}

#
# _get_photo_info 
#
# Given a flickr photo, gets its info
#
sub _get_photo_info {
    my ($self, $photo) = @_;

    my $url = 'http://api.flickr.com/services/rest/?method=flickr.photos.getInfo';
    $url .= '&api_key=' . API_KEY;
    $url .= '&photo_id=' . $photo->{id};
    $url .= '&secret=' . $photo->{secret};

    my $resp = $self->ua_get_page($url);
    unless ($resp->is_success) {
        return undef;
    }

    my $info = XMLin($resp->content);

    return $info;
}

1;
