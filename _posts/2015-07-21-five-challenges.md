---
title: Answers to the "Five Programming Problems every Software Engineer [...]
date: 2015-07-21
category: develop
---

I just read the post by <a href="https://blog.svpino.com/about">Santiago L. Valdarrama</a> titled
<a href="https://blog.svpino.com/2015/05/07/five-programming-problems-every-software-engineer-should-be-able-to-solve-in-less-than-1-hour">
"Five programming problems every Software Engineer should be able to solve in less than 1 hour"
</a>. In this he describes a set of five problems he usually gives to candidates for a position
during an interview, expecting them to come up with a solution in less than an hour.

While my clock is still ticking I decided to live-blog my solutions. The language of choice in my case is <a href="http://livescript.net/">LiveScript</a>.

## Challenge 1: Sums

> Write three functions that compute the sum of the numbers in a given list using a for-loop, a while-loop, and recursion.

This one is easy:

```coffeescript
sum_for = (ints) ->
	sum = 0
	for x in ints
		sum += x
	sum

sum_while = (ints) ->
	sum = 0
	i = 0
	while i < ints.length
		sum += ints[i]
		i++
	sum

sum_rec = (ints) ->
	if ints.length == 1
		ints[0]
	else
		ints[0] + sum_rec(ints.slice(1))
```

## Challenge 2: Zipper

> Write a function that combines two lists by alternatingly taking elements.
> For example: given the two lists [a, b, c] and [1, 2, 3], the function should
> return [a, 1, b, 2, c, 3].

We assume for simplicity that `as` and `bs` have te same length:

```coffeescript

zip = (as, bs) ->
	answer = []
	for ,i in as
		answer.push as[i]
		answer.push bs[i]
	answer
```

## Challenge 3: Fibonacci

> Write a function that computes the list of the first 100 Fibonacci numbers.
> By definition, the first two numbers in the Fibonacci sequence are 0 and 1,
> and each subsequent number is the sum of the previous two. As an example,
> here are the first 10 Fibonnaci numbers: 0, 1, 1, 2, 3, 5, 8, 13, 21, and 34.

```coffeescript
fibo = ->
	fibos = [0,1]
	for i in [2 to 99]
		fibos[i] = fibos[i-1] + fibos[i-2]
	fibos
```

## Challenge 4: Largest Possible Number

> Write a function that given a list of non negative integers, arranges them
> such that they form the largest possible number. For example, given [50, 2,
> 1, 9], the largest formed number is 95021.

We'll do this one recursively as well. Contrary to the solutions found on the
internet we use a brute-force approach, checking all possible combinations and
discarding the worst until one remains:

```coffeescript
withoutAt = (a, i) ->
  a.slice(0, i).concat(a.slice(i+1))
	
lpn = (ints) ->
	if ints.length == 0
		""
	else
		[parseInt(("" + x) + lpn(withoutAt(ints,i))) for x, i in ints].sort!.reverse![0]
```

## Challenge 5: Pluses and Minuses

> Write a program that outputs all possibilities to put + or - or nothing
> between the numbers 1, 2, ..., 9 (in this order) such that the result is
> always 100. For example: 1 + 2 + 34 - 5 + 67 - 8 + 9 = 100.

Again, a recursive approach is used. We construct a term by either
attaching the next digit using a plus, a minus or directly next to the
previous digit. As soon as we run out of additional characters, i.e. when
we used the 9, we check if the resulting string gives 100 when evaluated as
a JS expression.

```coffeescript
pm = (rem, prevString) ->
	if rem.length == 0
		if eval(prevString) == 100
			console.log prevString
	else
		pm rem.slice(1), (if prevString == "" then "" else prevString + " + ") + rem[0]
		pm rem.slice(1), prevString + " - " + rem[0]
		pm rem.slice(1), prevString + "" + rem[0]

pm [1 to 9], ""
```

## Conclusion

Thanks to Santiago for these challenges. It provided me with an excuse to get to know
LiveScript a little bit better, and the tasks really show how recursion can be applied
when it makes sense.

I took a look at the solution for challenge 5 by Santiago himself
([link](https://blog.svpino.com/2015/05/08/solution-to-problem-5-and-some-other-thoughts-about-this-type-of-questions)).
The approach he took seems similar to mine, but he has to implement the expression parsing himself, while
JS provides the (admittedly controversial) feature/bug of being able to execute source code at runtime. In this
case this greatly reduces the amount of code that has to be written.

