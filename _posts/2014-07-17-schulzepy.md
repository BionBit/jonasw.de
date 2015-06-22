---
title: Implementing the Schulze-Method with Python
categories: [Python]
date: 2014-07-20 13:32:48
abstract: "An introduction of the Schule Voting Method and a description of a simple and naive implementation"
---

The Schulze Method is a voting systems that has some nice properties setting it
apart from other, more widely used voting systems.  Wikipedia has a rather
short [list of users](http://en.wikipedia.org/wiki/Schulze_method#Users)
showing that pretty much only the Pirate Parties, Linux Distributions and other
development groups, but also some student governments at universities use
it.

As part of an assignment for a course we had to implement this method. I will
show my implementation below and explain how I did it.

## Overview: The Schulze Method

## The Implementation

The Schulze Method defines <math><mi>d</mi><mfenced open="[" close="]" seperators=","><mi>V</mi><mi>W</mi></mfenced></math> to be the number of voters
preferring <math><mi>V</mi></math> to
candidate <math><mi>W</mi></math>.
This "function" was implemented using a Python dictionary. The
terse syntax Python provides enables us to access the elements literally the
same way we do in the mathematical definition.

Let's assume the preference relations are expressed as a list of tuples,
specifying the number of voters having this preference relation and a string of
candidates (represented by a character) from top to bottom.

Our first step is to calculate the set of candidates. This is easy, as each
preference relation is assumed to contain all candidates, so we can just setify
one of these (the easiest is the first).

```python
candidates = set(preferences[0][1])
```

`dict.fromkeys` creates a dictionary with the keys given in the parameter,
optionally setting the values to the second parameter (we use `0`):

```python
d = dict.fromkeys([(a,b) for a in candidates for b in candidates if a != b], 0)
```

This line reads a lot like the equivalent algebraic notation:<math>
	<mi>d</mi><mfenced open="[" close="]" seperators=","><mi>V</mi><mi>W</mi></mfenced><mo>=</mo><mn>0</mn>
	<mspace width="2ex" />
	<mo>∀</mo><mi>a</mi><mo>&#x2200;</mo><mi>b</mi>
	<mspace width="1ex" />
	<mi>a</mi><mo>&#x2208;</mo><mi>C</mi><mo>,</mo><mspace width="1ex" />
	<mi>b</mi><mo>&#x2208;</mo><mi>C</mi><mo>,</mo><mspace width="1ex" />
		<mi>a</mi><mo>&#x2260;</mo><mi>b</mi>
</math>. The syntactical feature used here is called [list comprehensions](https://docs.python.org/3/tutorial/datastructures.html#list-comprehensions).

The next step is to count each time candidate `A` was preferred to candidate
`B`. A candidate is preferred if it appears before the other in the preference
relation string, e.g. if the string is `"ABC"`, `A` is preferred to `B` and to
`C`, but also `B` is preferred to `C`. If five voters use the relation
mentioned above, <math><mi>d</mi><mfenced open="[" close="]" seperators=","><mi>V</mi><mi>W</mi></mfenced></math> will be increased by 5.

```python
    for (weight, relation) in preferences:
        localWinnings = [(relation[index], localLoser) for index in range(len(relation) - 1) for localLoser in relation[index+1:]]
        for pair in localWinnings:
            d[pair] += weight
```

We can ignore the path <math><mi>X</mi><mo>,</mo><mi>Y</mi></math> if the reverse path has at least the same width:
```python
    for pair in d:
        if d[pair] <= d[swap(pair)]:
            d[pair] = 0
```

We now have to iterate over all the possible paths, to find out which
is the widest from each start to each end.

```python
    for (i, j, k) in [(a,b,c) for a in candidates for b in candidates for c in candidates if a != b and a != c and b != c]:
        indirectPathWidth = min(d[i, j], d[j,k])
        directPathWidth = d[i,k]
        if indirectPathWidth > directPathWidth:
            d[i,k] = indirectPathWidth

    return candidates - {pair[0] for pair in d if d[pair] < d[swap(pair)]}
```

