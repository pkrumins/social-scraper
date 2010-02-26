Social scraper is a Perl program and a bunch of Perl modules (plugins) that
scrape various social websites, such as reddit, digg, stumbleupon, delicious,
flickr, simply, boingboing, wired, for content that matches the given
patterns.

This program was written by Peteris Krumins (peter@catonmat.net).
His blog is at http://www.catonmat.net  --  good coders code, great reuse.

The program was written as a part of picurls.com website (currenly broken,
will fix some time later). The social scraper Program was described in this
article:

http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one/

------------------------------------------------------------------------------

The basic idea of the data scraper is to crawl websites and to extract the
posts in a human readable output format. I want it to be easily extensible via
plugins and be highly reusable. Also I want the scraper to have basic
filtering capabilities to select just the posts which I am interested in.

There are two parts to the scraper - the scraper library and the scraper
program which uses the library and makes it easier to scrape many sites at
once.

The scraper library consists of the base class 'sites::scraper' and plugins
for many various websites. For example, Digg's scraper plugin is 'sites::digg'
(it inherits from sites::scraper).

The constructor of each plugin takes 4 optional arguments - pages, vars,
patterns or pattern_file:

 * pages  - integer, specifies how many pages to scrape in a single run,
 * vars - hashref, specifies parameters for the plugin,
 * patterns - hashref, specifies string regex patterns for filtering posts,
 * pattern_file - string, path to file containing patterns for filtering posts

Here is a Perl one-liner example of scraper library usage (without scraper
program). This example scrapes 2 most popular pages of stories from Digg's
programming section, filtering just the posts matching 'php' (case
insensitive):

perl -Msites::digg -e '
    $digg = sites::digg->new(
        pages    => 2,
        patterns => {
            title   => [ q/php/ ],
            desc    => [ q/php/ ]
        },
        vars     => {
            popular => 1,
            topic   => q/programming/
        }
    );
    $digg->scrape_verbose'


Here is the output of the plugin:

    comments: 27
    container_name: Technology
    container_short_name: technology
    description: With WordPress 2.3 launching this week, a bunch of themes \
      and plugins needed updating. If you're not that familiar with PHP, \
      this might present a slight problem. Not to worry, though - we've \
      collected together 20+ tools for you to discover the secrets of PHP.
      human_time: 2007-09-26 18:18:02
    id: 3587383
    score: 921
    status: popular
    title: The PHP Toolbox: 20+ PHP Resources
    topic_name: Programming
    topic_short_name: programming
    unix_time: 1190819882
    url: http://mashable.com/2007/09/26/php-toolbox/
    user: ace77
    user_icon: http://digg.com/users/ace77/l.png
    user_profileviews: 17019
    user_registrered: 1162332420
    site: digg

Each story is represented as a paragraph of key: value pairs. In this case the
scraper found 2 posts matching PHP.

Any program taking this output as input is free to choose parts of information
they want to use.

It is guaranteed that each plugin produces output with at least 'title', 'url'
and 'site' fields.

The date of the post is extracted, if available, is extracted by two fields
'unix_time' and 'human_time'.

To create a plugin, one must override just three methods from the base class:

 * site_name - method should return a unique site id which will be output
               in each post as 'site' field,
 * get_page_url - given a page number, the method should construct a URL to
                  the page containing posts,
 * get_posts - given the content of the page located at last get_page_url
               call, the subroutine should return an array of hashrefs
               containing key => val pairs containing the post information.

It's very difficult to document everything the library does. It would take a
few pages of documentation to document this simple library. If you are more
interested in it, please take a look at the sources.

The program is called scraper.pl. Running it without arguments prints its
basic usage:

  Usage: ./scraper.pl <site[:M][:{var1=val1; var2=val2 ...}]> ...
                      [/path/to/pattern_file]

  Crawls given sites extracting entries matching optional patterns in
  pattern_file.
  Optional argument M specifies how many pages to crawl, default 1.
  Arguments (variables) for plugins can be passed via an optional { }.

The arguments in { } get parsed and then get passed to constructor of site.
Also a number of sites can be scraped at once.

For example, running the program with the following arguments:

  ./scraper.pl reddit:2:{subreddit=science} stumbleupon:{tag=photography}
               picurls.txt

Would scrape two pages of science.reddit.com and a page of StumbleUpon website
tagged 'photography' and use filtering rules in the file 'picurls.txt'.

This is how the output of this program looks:

    desc: Morning Glory at rest before another eruption, \
          Yellow Stone National Park.
    human_time: 2007-02-14 04:34:41
    title: public-domain-photos.com/free-stock-photos-4/travel/yellowstone
    unix_time: 1171420481
    url: http://www.public-domain-photos.com/free-stock-photos-4/travel/ \
         yellowstone/morning-glory-pool.jpg
    site: stumbleupon

See the original post for more documentation:

http://www.catonmat.net/blog/making-of-picurls-popurls-for-pictures-part-one/


------------------------------------------------------------------------------

Have fun scraping the Internet!


Sincerely,
Peteris Krumins
http://www.catonmat.net

