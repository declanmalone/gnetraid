# gnetraid #

A collection of files relating to distributed, RAID-like storage and transport mechanisms

This repository contains various tools, libraries and demos for implementing a RAID-like storage system on a network. It's mostly written in Perl, though there are some elements written in C, including some Perl XS (C) code written to improve the performance of critical parts. All parts are licensed under version 2 (or later&mdash;your choice) of the GPL, except for any linkable C libraries, which are usable in other code under the terms of the Lesser GNU Public Licence (LGPL). Other parts may have slightly different licences depending on intended use (eg, Perl licence for any pure-Perl demo code).

As it stands, the project is more of a loose collection of elements that can be used to create applications rather than a finished application itself. The one exception to this is the contents of the [Media-RAID/](https://github.com/declanmalone/gnetraid/tree/master/Media-RAID/trunk) folder, described below.

## Project Focus

There are three main focuses for this project:

- Achieving RAID-like redundancy by creating "shares" (using Rabin's Information Dispersal Algorithm) which can be stored on different disks 
- Using broadcasting (UDP or multicast) to efficiently send files from one machine to many (where they may either be stored as "replicas"&mdash;100% copies of the file&mdash;or "shares", with the receiving machine responsible for generating the share locally)
- Using event-based/coroutine-based libraries (such as Perl's POE or C's libev/libevent) to implement distributed network-based protocols for managing replica/share storage
 
The goals for this project can be summed up with a nice acronym coming from an older project called [LOCKSS](http://en.wikipedia.org/wiki/LOCKSS) which stands for "Lots Of Copies Keeps Stuff Safe". This project has nothing to do with the official LOCKSS project (and apparently "LOCKSS" is trademarked by Stanford University), but as a general description I think it is fitting. My project differs significantly from the official LOCKSS project in my focus on using Rabin's IDA as a key part of "keeping stuff safe". The original project seems to only use full file copies (or "replicas", as I call them) to ensure file redundancy, whereas I want to use a combination of "shares" and "replicas".

## Rabin's Information Dispersal Algorithm (IDA)

### Introduction

In technical terms, this allows you to create a number of "shares" from an original file. These shares have the property that if you have a sufficient number of them (called a "threshold" or "quorum") then you can reconstruct the original file. Having fewer of the shares than this threshold number means that no part of the file can be recovered (though there might be *some* small amount of information leakage).

The way this works is described in detail in the documentation for the Crypt::IDA perl module which is found in the [Crypt-IDA/trunk/](https://github.com/declanmalone/gnetraid/tree/master/Crypt-IDA/trunk) folder. A simpler explanation can be made by analogy to "secret-sharing schemes", which are mathematically quite similar to IDA.

In [Shamir's secret-sharing scheme](http://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing), we consider a case where a secret is to be shared among some number of people, which we can denote as "n". We want to give eacn of these people a part (or share) of the secret, but want also want to make it so that we require a minimum number of these shares (called the threshold, as above, and denoted as k) to be combined to recover the secret. This description can be seen to be almost identical to the description of Rabin's IDA as described above.

More concretely, imagine a scenario where we want to split up the secret among any number of people (any n) but we want to require two people (k=2) to combine their shares together. This can be easily done by:

- encoding the secret as a point in the 2-d plane (by, say, breaking it into two parts and treating each point as an X or Y coordinate);
- generating a random line through that point for each person who will receive a share;
- handing out the equation one line per participant.

With this setup, any individual doesn't have enough information to recover the secret since there are an infinite number of points on their line. However, if two people put their equations together they can calculate the intersection of their respective lines. Since all lines go through the same point, any pair of lines will have the same point of intersection and so any pair of participants can combine their information to recover that point, which is the same as recovering the secret.

The same scenario can be generalised for any value of k by considering a k-dimensional space, with 2-d points being replaced with k-d points and lines being replaced with k-d planes or hyperplanes. It can be generalised for higher values of n by simply generating more random lines/planes/hyperplanes that pass through the secret point within that space.

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

The k and n values can also calculate three other important figures:

* the number of disk failures tolerated = n - k
* the *fraction* of disk failures tolerated = (n - k) / n
* the degree of space overhead = (n - k) / k

Following on from the previous example, we can see that the (k=3, n=4) scheme can tolerate n - k = 1 disk failure, and expressed as a fraction this is (4 - 3) / 4 or one quarter of the disks. The amount of space overhead is ( 4 - 3 ) / 3 = one third (or 20Mb).

One of the major benefits of IDA over RAID is that it can be tuned depending on whether the goal is improved redundancy or improved space efficiency. RAID restricts you to certain standard configurations, each with their own fixed k and n values. Hybrid RAID systems are possible, but they generally involve layering one RAID system (including RAID-0, which is striped only, but has no redundancy) on top of another. The space overheads of such hybrid RAID arrays is the accumumalation of the overheads *at each level*. This leads to the fact that for a given required level of redundancy, there is probably a set of IDA parameters which is more efficient than RAID.

Another disadvantage of hybrid RAID arrays is that it is not possible to give a simple fraction describing the number of disk failures that the system can tolerate. Each layer will have its own tolerances, and the loss of certain key disks can render the entire array unreadable. Analysing the actual failure rates requires an exercise in figuring out all the permutations. By contrast, each share in an IDA scheme are fundametally interchangeable, with the probablity of failure of the entire system following naturally from the equation for the fraction of tolerated disk failures given above.

(insert table of some sample k,n values here)

One other fringe benefit of IDA is that it is easy to add more shares at a later time (increasing n) if more redundancy is required. Changing the overall redundacy level of a RAID array usually means rebuilding the entire array. This ability makes it interesting for, eg, dynamically altering the availability of a file in response to demand.

### Application Niches



### Summary of pros and cons

As per De Bono's "PMI analysis" technique, here are some "plus", "minus" and "interesting" points for IDA.

Plus points:

* tunable
* can be set up to be more space-efficient than RAID
* can be set up to have better redundancy than RAID
* even importance attached to all shares (no key points of failure)
* lends itself well to distributed creation of shares (especially if combined with multicast)
* very good for archival data
* easy to analyse space and reliability metrics
* extra redundancy easy to add later (requires reconstruction step or an existing replica)
* security: individual shares leak little to no information if threshold is not met (so having a few silos cracked might not matter)
* security: secure erase possible if decoding keys are kept secret (say in a central location)
* with high redundancy levels, can be used in applications where high availability is more important than storage space (while still requiring less space than replica-based HA systems)

Minus points:

* software-based implementation (slow)
* mathematically more complicated than RAID (which often just uses XOR)
* slight file size increase (if decoding matrix needs to be stored with shares, though it need not be)
* decoding complexity is O(k) compared to RAID's O(1) (IDA's encoding complexity is O(n))
* also need to invert a k by k matrix before decoding, depending on which shares are selected during reconstruction
* increasing k at a later time requires rebuilding the entire IDA scheme (analogous to rebuilding a RAID array, but more costly)
* not a complete security solution (requires external key management protocols, secure transmission channels, protocols to prevent silos presenting damaged or deliberately wrong shares, and also optionally encryption of data before share creation)
* encoding and decoding costs increase latency
* very low level (needs software stack or applications to make good use of it)
* no standard software stacks (and my Perl-based implementation is OK, but quite slow)

Interesting points:

* since it's not implemented in hardware (eg, a RAID controller) it may make sense in a distributed network environment (potentially turning a minus into a plus)
* might be useful as a component in a reliable ACK-free multicast protocol (in fact, [udpcast](https://www.udpcast.linux.lu/) uses a scheme like this (Luigi Rizzo's [FEC](http://www.iet.unipi.it/~luigi/fec.html), along with striping of blocks), and a [Digital Fountain scheme](http://en.wikipedia.org/wiki/Fountain_code) like [Online Codes](http://en.wikipedia.org/wiki/Online_codes) can use it as a "pre-coding" or "outer code" step)
* implementation using cheap, low-powered commodity hardware (eg, Raspberry Pi with attached USB disks)
* when used for "cold" storage (ie, archival data), machines and/or disks can be powered down when not needed (or data could be stored on media such as tapes or optical disks)
* shares need not be stored in silos on a 1:1 basis (particularly useful if n is modified dynamically in response to frequent accesses, so shares can form the basis of a "granular" cache&mdash;using filesize/k as the basic unit/quantum&mdash;providing good balance between availability and required storage space)
* by themselves, shares provide moderate levels of security (privacy), especially if an attacker does not know which shares form a set (also, eg, [Chaffing and Winnowing](http://en.wikipedia.org/wiki/Chaffing_and_winnowing))
* possibility of implementation in hardware (eg, Parallella's Epiphany *or* FPGA part, PS3's SPU co-processors) or with specific versions optimised for certain CPUs (eg, ARM NEON or other SIMD architectures)
* a hybrid share/replica system seems like both parts would complement each other and could be used for a variety of storage scenarios and work flows (dynamic scaling for both hot and cold data)
* secret-sharing schemes are just way cool, and since there's no "key" as with traditional encryption schemes you can't be forced to divulge them (through legal or other means)

### A complete application: media-RAID

