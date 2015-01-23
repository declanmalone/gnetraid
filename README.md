# gnetraid
A collection of files relating to distributed, RAID-like storage and transport mechanisms

This repository contains various tools, libraries and demos for implementing a RAID-like storage system on a network. It's mostly written in Perl, though there are some elements written in C, including some Perl XS (C) code written to improve the performance of critical parts. All parts are licensed under version 2 (or later&mdash;your choice) of the GPL, except for any linkable C libraries, which are usable in other code under the terms of the Lesser GNU Public Licence (LGPL). Other parts may have slightly different licences depending on intended use (eg, Perl licence for any pure-Perl demo code).

As it stands, the project is more of a loose collection of elements that can be used to create applications rather than a finished application itself. The one exception to this is the contents of the [Media-RAID/](https://github.com/declanmalone/gnetraid/tree/master/Media-RAID/trunk), described below.

