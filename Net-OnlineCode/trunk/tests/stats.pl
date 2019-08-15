#!/usr/bin/perl

#
# Re-think claims made in the papers
#

# I think that I may have been misreading the claims in the papers,
# which is why the promises script (based on this reading) did not
# bear out my understanding of the claims.
#
# Here, I'm going to just crunch some numbers based on:
#
# Number of blocks: 5,000, 32,000, 100,000
# epsilon: 0.01
# delta: 0.005
# k: 3
#
# (These combinations all evaluate to F=2114)
#

#
# There are basically two claims to evaluate:
#
# 1. receiving (1 + e) * n' check blocks should be enough to decode a
#    fraction (1 - e/2) of the composite message
#
# 2. if a fraction delta of the original message is missing
#    [equivalently, we have a random fraction 1-delta of it], then any
#    random fraction (1-delta) of the auxiliary blocks will complete
#    the original message with probability 1 - delta ^ k
#
# This second claim corrects my previous understanding which treated
# message blocks and auxiliary blocks as being effectively equal.
#
# This is not the case. If delta was 10% and we were missing that
# percentage of the original message blocks, then we would need 90% of
# the auxiliary blocks to have (1 - delta ^ k) probability of
# decoding. However, since the (1-e/2) fraction of the composite
# message may be spread unequally between message and auxiliary
# blocks, we may have too few decoded message blocks to achieve
# recovery with the auxiliary blocks. Likewise, the opposite case (too
# few decoded auxiliary blocks) may arise.
#
# The two claims seem to resolvable by saying that the (1-e/2)
# fraction of the composite blocks should correspond to the minimum
# number of check blocks needed to have the stated 1-delta^k
# probability of decoding the full message. In practice, in addition,
# we would have to have a threshold number of decoded message blocks
#
# Reading further, I see that:
#
# 3. knowing an arbitrary (1-e/2) fraction of the composite message is
#    sufficient to decode the entire message with probability
#    1 - (e/2)^(q+1)
#
# We know that n' = n (1 + k*delta), so substitute this into claim 1
# to get:
#
#   receiving (1 + e) * (1 + k*delta) * n check blocks should decode
#   the message with probability 1 - (e/2)^(q+1)
#
# Various values computed by hand:
#
# n        1+e      1+k*delta   product  check        probability
# 5000     1.01     1.015       1.02515    5125.75    0.999999999375
# 32000                         1.02515   32804.80
# 100000                        1.02515  102515.00
# 1000000                       1.02515 1025150.00
#
# However, the number of predicted check blocks above don't match
# the observed values.
#
# n        1+e      1+0.55ke    product   check        probability
# 5000     1.01     1.0165      1.026665  5133.325     0.999999999375
# 32000                         1.026665  32853.28
# 100000                        1.026665  102666.5
# 1000000                       1.026665  1026665
#
# if 0.55ke = k * delta, then delta=0.55 * 0.01 = 0.0055:
#
# n        1+e      1+k*delta   product  check        probability
# 5000     1.01     1.0165      1.026665  5133.325     0.999999999375
# 32000                         1.026665  32853.28
# 100000                        1.026665  102666.5
# 500000                        1.026665  513332.5
# 1000000                       1.026665  1026665
#
# Some random trials on 1m blocks using 1+0.55ke setting:
#
# 1024948  1024186  1024895  1023632  1021755
# 1024068  1023104  1021670  1021660  1022753
#
# All of these are comfortably satisfy the claims (<1026665 blocks).
#
# Basically, it seems that the claim is only true asymptopically as n
# grows.
#
# Doing another set of random trials for 500,000 blocks:
#
# 512379  511768  511012  512193  510726
# 511578  512116  511837  511300  511467
