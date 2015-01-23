# gnetraid #

A collection of files relating to distributed, RAID-like storage and transport mechanisms

This repository contains various tools, libraries and demos for implementing a RAID-like storage system on a network. It's mostly written in Perl, though there are some elements written in C, including some Perl XS (C) code written to improve the performance of critical parts. All parts are licensed under version 2 (or later&mdash;your choice) of the GPL, except for any linkable C libraries, which are usable in other code under the terms of the Lesser GNU Public Licence (LGPL). Other parts may have slightly different licences depending on intended use (eg, Perl licence for any pure-Perl demo code).

As it stands, the project is more of a loose collection of elements that can be used to create applications rather than a finished application itself. The one exception to this is the contents of the [Media-RAID/ folder](https://github.com/declanmalone/gnetraid/tree/master/Media-RAID/trunk), described below.

There are three main focuses for this project:

- Achieving RAID-like redundancy by creating "shares" (using Rabin's Information Dispersal Algorithm) which can be stored on different disks 
- Using broadcasting (UDP or multicast) to efficiently send files from one machine to many (where they may either be stored as "replicas"&mdash;100% copies of the file&mdash or "shares", with the receiving machine responsible for generating the share locally)
- Using event-based/coroutine-based libraries (such as Perl's POE or C's libev/libevent) to implement distributed network-based protocols for managing replica/share storage
 
The goals for this project can be summed up with a nice acronym coming from an older project called [LOCKSS](http://en.wikipedia.org/wiki/LOCKSS) which stands for "Lots Of Copies Keeps Stuff Safe". This project has nothing to do with the official LOCKSS project (and apparently "LOCKSS" is trademarked by Stanford University), but as a general description I think it is fitting. My project differs significantly from the official LOCKSS project in my focus on using Rabin's IDA as a key part of "keeping stuff safe". The original project seems to only use full file copies (or "replicas", as I call them) to ensure file redundancy, whereas I want to use a combination of "shares" and "replicas".


