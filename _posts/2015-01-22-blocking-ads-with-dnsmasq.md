---
title: Blocking Ads with dnsmasq
date: 2015-01-22
category: DNS
abstract: "A simple script to block ads at the router"
---

For a while I have an OpenWRT router installed,
running a Linux to which I have full root access.
One of the services on this devices is a DNS resolver.
I use this to block all ads that websites try to sneak into
my view.

To accomplish this I combine block lists from multiple sources
and configure the resolver to redirect them into a black hole.
The configuration for dnsmasq is generated with the following Makefile.

You can execute it as follows:
<code>make SERVER=192.168.1.1 BLACKHOLE=192.168.1.234</code>, if all requests
should be redirected to 192.168.1.234 and your router is reachable at 192.168.1.1.

<script src="https://gist.github.com/thriqon/259e445376e36e82980c.js"></script>

(based on [PiHole](http://jacobsalmela.com/raspberry-pi-block-ads-adtrap/)).

To improve the performance, you can choose to download multiple files in parallel
by specifying another parameter <code>-j</code>, use <code>-j4</code> to run four tasks
in parallel.

I hope this helps some people to make the web a faster place!
