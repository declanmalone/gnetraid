# gnetraid #

A collection of files relating to distributed, RAID-like storage and transport mechanisms

This repository contains various tools, libraries and demos for implementing a RAID-like storage system on a network. It's mostly written in Perl, though there are some elements written in C, including some Perl XS (C) code written to improve the performance of critical parts. All parts are licensed under version 2 (or later&mdash;your choice) of the GPL, except for any linkable C libraries, which are usable in other code under the terms of the Lesser GNU Public Licence (LGPL). Other parts may have slightly different licences depending on intended use (eg, Perl licence for any pure-Perl demo code).

As it stands, the project is more of a loose collection of elements that can be used to create applications rather than a finished application itself. The one exception to this is the contents of the [Media-RAID/](https://github.com/declanmalone/gnetraid/tree/master/Media-RAID/trunk) folder, described below.

## Project Focus

There are three main focuses for this project:

- Achieving RAID-like redundancy by creating "shares" (using Rabin's Information Dispersal Algorithm) which can be stored on different disks 
- Using broadcasting (UDP or multicast) to efficiently send files from one machine to many (where they may either be stored as "replicas"&mdash;100% copies of the file&mdash;or "shares", with the receiving machine responsible for generating the share locally)
- Using event-based/coroutine-based libraries (such as Perl's POE or C's libev/libevent) to implement distributed network-based protocols for managing replica/share storage
 
The goals for this project can be summed up with a nice acronym coming from an older project called [LOCKSS](http://en.wikipedia.org/wiki/LOCKSS) which stands for "Lots Of Copies Keeps Stuff Safe". This project has nothing to do with the official LOCKSS project (and apparently "LOCKSS" is trademarked by Stanford University), but as a general description I think it is fitting. My project differs significantly from the official LOCKSS project in my focus on using Rabin's IDA as a key part of "keeping stuff safe". The original project seems to only use full file copies (or "replicas", as I call them) to ensure file redundancy, whereas I want to use a combination of "shares" and "replicas". The official LOCKSS project is much more high-level than my project here, which is decidedly focused on the low-level aspects of replication and redundancy.

Besides the three main focuses listed above, I definitely have a focus on using small, low-powered machines (such as the [Raspberry Pi](http://www.raspberrypi.org/) or hardkernel's range of ARM-based [ODROID computers](http://hardkernel.com/)) combined with relatively small external USB disks. I don't exclude using more powerful machines with larger disks (or indeed arbitrary Internet hosts), but I believe that smaller machines can provide much more cost-effective solutions, particularly for archival purposes.

Along with my interest in these areas, I'm also interested in some related ares, some of which might eventually be incorporated into this repository. For example:

* append-only storage structures for building databases on machines with flash storage (in the spirit of [FAWN](http://www.cs.cmu.edu/~fawnproj/))
* distributed/federated document indexing and searching
* automatic document clustering based on keywords
* developing distributed applications in general
* distributed network-based file systems in particular
* security/cryptography in a network environment
* distributed databases as a component in a distributed file system
* distributed de-duplication and identification of "at risk" files (those with only a single extant replica)
* [FUSE](http://fuse.sourceforge.net/): Filesystems in User Space
* GTK, Glade, Perl and POE in general (also C, Perl/XS)
* distributed transcoding of video files (a potential application for Pi clusters as well as some of the tools here)

That's rather a broad selection, but it can mostly be summed up as finding useful things to do with small, wimpy clusters of machines, whether they're all on a local LAN or dotted around the Internet.

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

There are basically two jobs that IDA is extremely well suited to:

* as a network-based alternative to RAID for securely storing archival material; and
* as an alternative or complement to replica-based caching of data for applications requiring fast access (also in a network context)
 
As for the applications, I think that I've given enough information in this document and elsewhere (within my code and man pages) to understand why IDA is good for a redundant *storage* system, along with why it's probably better for archival data rather than "hot" data (lack of mature software stacks and/or hardware-based encoding and decoding being two significant ones) so I'll pass over that and move on to briefly explaining about using IDA for an improved caching algorithm. This description is quite speculative, so feel free to jump ahead to the next section dealing with the "Pros and Cons" of IDA if you want.

The competition IDA has in this area will be replica-based caching or data availability systems. I can give two real-world examples to illustrate:

* in a local RAID-1 setup, since the data is replicated across two disks, we can either request data from the least-busy disk or request data from both at once and use the data from whichever completes the request first
* in a network context, the [Axel program](http://axel.alioth.debian.org/) for Linux systems is a download accelerator that works by looking up a list of mirrors for a given file and downloading a fraction of the file from each of them, thus while receiving the full file will take as long as the longest individual download, each of those downloads is shorter and as they finish more bandwitdh becomes available to complete the slower downloads
 
Using IDA to download a file can take elements from both of these. We can take the "over-requesting" idea from the first example and the idea of multiple network-based "silos" from the second. Some network links will be slower than others so often we may come across a link that is so slow that we would have been better off either abandoning the download, or starting off another download (of the same data) from another mirror. However, that approach will seldom work out well in a replica- (mirror-) based system since we have no way of knowing in advance which downloads will be slow to complete, and neither do we know whether the redundant download will be any quicker overall.

With IDA, however, if we suspect that some download links will be slow, instead of asking for the minimum 'k' downloads required to complete the file, we can instead fire up 'k+1' or even 'k+2' download sessions. The assumption here is that on average the overheads in bandwidth required to transfer these shares is less than the time taken, on average, for the longest download to complete had we only requested the minimum 'k' shares. This assumption isn't a good one for a local network with relatively few subnets and little traffic congestion, but for nodes on the Internet (with multiple different routes, each having a different speed and degree of congestion), it might well be. So this is the first way in which IDA *may* speed up access time: if you ask for more than k shares and immediately cancel any remaining downloads once *any* k of them are received, those k shares will be enough to recover the file. This is in contrast to the Axel program, where each download is not interchangeable with other downloads because it represents a unique section of the file.

We can play with this idea of making the files we need to access available with a high level of redundancy (whether through replicas or shares) by considering two ways to improve their availabilty (primarily determined by how fast we can access them) when we need them. They are simply:

* keeping a redundant copy locally (ie, local caching)
* having more redundancy *close by* (ie, no more than a few network hops away)

Obviously, the more local cache we have, the fewer network requests will have to be made. With a replica-based system, cache entities will generally correspond to a single file, so the cache will be all-or-nothing for a particular entity: either the file will be in the cache or it won't. By contrast, with an IDA sheme the basic caching unit can be a *share*, so that when space is needed it need not delete complete files, but some fraction thereof (ie, one or more shares) instead. This represents a major improvement on local replica-based caching since if we get a cache miss and need to reconstruct the file, we need only request as many shares as are required to satisfy the threshold (of course, we can also use the trick of over-requesting if we have a good reason to suspect that it will be effective).

The benefit of having more redundancy "close by" is one of load-balancing. By randomly selecting a subset of potential download nodes we will more often hit a node that is not so busy doing other things. Here, IDA also has several advantages over replica-based network caches, including:

* much lower overall storage overheads for the same level of redundancy
* with lower local storage costs (1/k times file size) more nodes can participate in the network cache
* better dynamic reponse to increased demand for a file (also with 1/k granularity)
 
Further improvements and advantages may also be considered if a reliable multicast channel is available:

* either full replicas or individual shares can be transmitted at not much more cost than sending to an individual node
* if using a distributed hash table (DHT) to locate shares then a single transmission sets up both the master and backup nodes where a given share will be saved
* possibility of dynamically rebalancing distribution of shares based on listening in to broadcast/multicast messages (eg, seamless handover from old DHT to a new one, along with other ["Quorum Sensing"](http://en.wikipedia.org/wiki/Quorum_sensing) behaviour)
 
In summary, IDA could have benefits over replica-based network cache schemes in three important areas:

* reduced memory usage (both overall and per node)
* smaller granularity, leading to more consistency
* less retransmission overhead in the case of a cache miss (fewer shares need be requested on average and shares are interchangeable)
 
There are some obvious downsides, too:

* increased complexity (both in design and overheads associated with IDA)
* need to keep at least one replica if dynamic addition of shares is envisioned
* lots of applications simply don't need a more granular cache
* possibility of increased network traffic to account for cache eviction events
* over-requesting places extra stress on finite network bandwidth
* best results will come from having a high k value, but that comes with increased decoding cost

While I don't advocate for replacing replica-based network caches in every circumstance, I still believe that it's an intriguing possibility for some applications. It would certainly be interesting to consider it as a storage backend for applications like, eg, memcached, especially if the data being cached have a high read:write ratio.

### Summary of pros and cons

As per De Bono's "PMI analysis" technique, here are some "plus", "minus" and "interesting" points for IDA.

Plus points:

* tunable
* can be set up to be more space-efficient than RAID
* can be set up to have better redundancy than RAID
* even importance attached to all shares (no key points of failure)
* lends itself well to distributed creation and storage of shares (especially if combined with multicast)
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
* decoding complexity is O(k) compared to RAID's O(1) (IDA's encoding complexity is O(n), but this can be distributed over n machines)
* also need to invert a k by k matrix before decoding, depending on which shares are selected during reconstruction
* increasing k at a later time requires rebuilding the entire IDA scheme (analogous to rebuilding a RAID array, but more costly)
* not a complete security solution (requires external key management protocols, secure transmission channels, protocols to prevent silos presenting damaged or deliberately wrong shares, and also optionally encryption of data before share creation)
* encoding and decoding costs increase latency
* very low level (needs software stack or applications to make good use of it)
* no standard software stacks (my Perl-based implementation is OK, but quite slow and low level)

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

