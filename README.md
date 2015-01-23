# gnetraid #

A collection of files relating to distributed, RAID-like storage and transport mechanisms

This repository contains various tools, libraries and demos for implementing a RAID-like storage system on a network. It's mostly written in Perl, though there are some elements written in C, including some Perl XS (C) code written to improve the performance of critical parts. All parts are licensed under version 2 (or later&mdash;your choice) of the GPL, except for any linkable C libraries, which are usable in other code under the terms of the Lesser GNU Public Licence (LGPL). Other parts may have slightly different licences depending on intended use (eg, Perl licence for any pure-Perl demo code).

As it stands, the project is more of a loose collection of elements that can be used to create applications rather than a finished application itself. The one exception to this is the contents of the [Media-RAID/ folder](https://github.com/declanmalone/gnetraid/tree/master/Media-RAID/trunk), described below.

## Project Focus

There are three main focuses for this project:

- Achieving RAID-like redundancy by creating "shares" (using Rabin's Information Dispersal Algorithm) which can be stored on different disks 
- Using broadcasting (UDP or multicast) to efficiently send files from one machine to many (where they may either be stored as "replicas"&mdash;100% copies of the file&mdash or "shares", with the receiving machine responsible for generating the share locally)
- Using event-based/coroutine-based libraries (such as Perl's POE or C's libev/libevent) to implement distributed network-based protocols for managing replica/share storage
 
The goals for this project can be summed up with a nice acronym coming from an older project called [LOCKSS](http://en.wikipedia.org/wiki/LOCKSS) which stands for "Lots Of Copies Keeps Stuff Safe". This project has nothing to do with the official LOCKSS project (and apparently "LOCKSS" is trademarked by Stanford University), but as a general description I think it is fitting. My project differs significantly from the official LOCKSS project in my focus on using Rabin's IDA as a key part of "keeping stuff safe". The original project seems to only use full file copies (or "replicas", as I call them) to ensure file redundancy, whereas I want to use a combination of "shares" and "replicas".

## Rabin's Information Dispersal Algorithm (IDA)

### Introduction

In technical terms, this allows you to create a number of "shares" from an original file. These shares have the property that if you have a sufficient number of them (called a "threshold" or "quorum") then you can reconstruct the original file. Having fewer of the shares than this threshold number means that no part of the file can be recovered (though there might be *some* small amount of information leakage).

The way this works is described in detail in the documentation for the Crypt::IDA perl module which is found in the [Crypt-IDA/trunk/ directory](https://github.com/declanmalone/gnetraid/tree/master/Crypt-IDA/trunk). A simpler explanation can be made by analogy to "secret-sharing schemes", which are mathematically quite similar to IDA.

In [Shamir's secret-sharing scheme](http://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing), we consider a case where a secret is to be shared among some number of people, which we can denote as "n". We want to give eacn of these people a part (or share) of the secret, but want also want to make it so that we require a minimum number of these shares (called the threshold, as above, and denoted as k) to be combined to recover the secret. This description can be seen to be almost identical to the description of Rabin's IDA as described above.

More concretely, imagine a scenario where we want to split up the secret among any number of people (any n) but we want to require two people (k=2) to combine their shares together. This can be easily done by:

- encoding the secret as a point in the 2-d plane (by, say, breaking it into two parts and treating each point as an X or Y coordinate);
- generating a random line through that point for each person who will receive a share;
- handing out the equations of the lines to all participants.

With this setup, any individual doesn't have enough information to recover the secret since there are an infinite number of points on their line. However, if two people put their equations together they can calculate the intersection of their respective lines. Since all lines go through the same point, any pair of lines will have the same point of intersection and so any pair of participants can combine their information to recover that point, which is the same as recovering the secret.

The same scenario can be generalised for any value of k by considering a k-dimensional space, with lines being replaced by planes or hyperplanes and for other values of n by simply generating more random lines/planes/hyperplanes that pass through the secret point within that space.

### Applications of Rabin's IDA

The first, and possibly most useful, application of IDA is as an alternative to convential RAID encoding. When RAID is used for data redundancy, it is usually used in one of the following ways:

* with *mirroring* (eg, RAID-1), two exact copies of the data are stored, with each copy being stored on a single disk. If one disk fails, the data on the other one is still available to recover the file
* with *parity* (eg, RAID-5), the data are spread evenly ("striped") across some number of disks (often 2) and a separate "parity" disk is calculated as the XOR of the data on the respective sectors of the striped data. If any one of the disk fails, the data is still recoverable by XORing the contents of the remaining disks (for the common case of 2 stripe disks and 1 parity disk&mdash;the parity calculations are more complicated if more stripe disks are used)

IDA generalises the whole concept of achieving data redundancy beyond these two standard RAID schemes. Since IDA is a generalisation, the above two RAID schemes could be implemented as a (k=1, n=2) IDA scheme (for RAID-1/mirroring) or a (k=2, n=3) IDA scheme (for RAID-5 with two "stripe" disks and one "parity" disk).

The formulation of an IDA scheme as involving some values of k (threshold) and n (total number of shares) allows for direct calculation of how much space the scheme takes up, both per disk and overall:

* the total number of disks required is n
* per disk, the space taken is proportional to 1/k
* overall, the space taken is proportional to n/k

The two fractions (1/k and n/k) should be multiplied by the total size of the file(s) being stored so, for example, storing a 60Mb file stored using a (k=3, n=4) will require:

* 4 disks in total
* 60Mb * 1/3 = 20Mb per disk
* 60Mb * 4/3 = 80Mb total

The k and n values can also calculate two other important figures:

* the number of disk failures tolerated = n - k
* the *fraction* of disk failures tolerated = (n - k) / n

Following on from the previous example, we can see that the (k=3, n=4) scheme can tolerate n - k = 1 disk failure, and expressed as a fraction this is (4 - 3) / 4 or one quarter of the disks.



### Application Niches



### Summary of pros and cons
