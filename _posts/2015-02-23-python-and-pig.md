---
title: Writing UDFs for Pig with Python
categories: [Hadoop, Python]
date: 2015-02-23 19:30:00
---

[Pig][1] is a powerful, yet concise scripting language to manipulate huge amounts of data with
expressive commands on a Hadoop cluster.
Common tasks such as joining data by common fields or grouping rows together
require boilerplate code when implemented with native MapReduce.

Even though Pig is powerful, the built-in functions and mechanisms have
limitations, and anyone implementing something non-trivial will
find them. To overcome this limitations Pig provides a plugin mechanism
with which users can supply _User Defined Functions_ (UDFs).

It is pretty well-known that these UDFs can be implemented in Java and
included from jar files, but it is possible to implement these as scripts
using JavaScript and Python as well.

During my last project I ran into some dead ends on what was achievable
with 'plain' Pig, so I implemented UDFs to bridge the gaps.
I think it is better to introduce such a feature with a real world
example than a contrived 'Hello, World!' example.

## The problem


My task was to create a datastructure with the following description
(which, by the way, is the perfect format to _PUT_ data into HBase):

```pig
mapped: {group: chararray,mappedTuple: map[]}
```

However, the data I had from previous steps was of the form:

```pig
topped: {group: chararray,result: {(x: chararray,y: double,z: chararray)}}
```

The data in the inner bag is sorted. I wanted to have the tuples in result
in a map with their position as key (with a prefix) and the values in the tuple
joined with a tab as separator, except the first entry (`x`).

## Hello, Jython

The python engine provided by Hadoop is not the 'usual' native python, but
the Java implementation _Jython_. We have to keep this in mind, especially
when we are used to Python 3 (Jython is 'still' in version 2.5.3).

My first implementation is this:

```python
@outputSchema("mappedTuple:map[]")
def rankToMapAndConcatExceptFirst(prefix, b):
  o = {}
  for i in enumerate(b):
    o[prefix + str(i[0])] = '\t'.join(map(unicode, i[1][1:]))
  return o
```

Let's take a look at this step by step. The first line
gives a hint to Pig what this function returns. This is important
as it determines how subsequent commands can be applied.
An overview over the syntax for different datatypes can be found
on the documentation for Mortardocs on [Writing Python UDFs][2].

The name of the function is long, but it describes well what is happening here.
I think it is perfectly okay to write such short scripts that are
specifically tailored to a use case even though they are not reusable.
If I ever had to do something similar again I'd just reimplement it, probably
in less time than refactoring the lazy approach.

By iterating over `enumerate(b)` we are getting a tuple of the index and the
value in each iteration. We join the entries of the tuple of the current item (`i[1]`)
starting from the second component (...`[1:]`) with a tab separator, after converting
each one of them to a string.
The results are then assigned to the prefix concatenated with the current index.

Please note that I'm not mapping with `str` here which was my first try. However,
in the Big Data world nothing is as it seems at first glance, and I was most certainly
getting unicode characters in the tuple (which Pig handles perfectly). By
using `unicode` the problems disappear.

## Register all the things!

Back in Pig we want to use this brand new UDF. To do this we first have
to `REGISTER` the file with the following command:

```pig
REGISTER 'enumerate.py' USING jython AS e;
```

We can then later invoke it with

```pig
mapped = FOREACH topped
	GENERATE group, e.rankToMapAndConcatExceptFirst('prefix-', result);
```

and get the desired result.

## Oozie

If you are submitting the Pig script via Oozie you have to take care
that the UDF is delivered with it. This can be achieved with
a `file` tag such as:

```xml
<pig>
	...
	<file>scripts/enumerate.py</file>
</pig>
```

Note that you can keep the UDF files in a separate directory, but Oozie will
always deliver them to the current directory of your Pig job, so just
require them as if they were always directly next to the Pig script.

[1]: http://pig.apache.org/docs/r0.14.0/
[2]: https://help.mortardata.com/technologies/pig/writing_python_udfs

