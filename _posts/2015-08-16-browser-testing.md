---
title: Can we isolate Units in the Browser? - Anatomy of a Bug
categories: develop tdd
---

The title says it all: Can we really call testing in the Browser with libraries
like QUnit or Mocha *unit* testing? Or do we have to accept some kind of breach
of the isolation separating two different test cases?

## Why I Ask

As you can imagine, this post was caused by a recent occurrence of such a
breach.  After we upgraded Ember addons we suddenly got tests failures in our
frontend tests. In our case, there were two, and they seemed to be as unrelated
as possible.  Funnily enough, this happened not every time, but only now and
then, like this:

{% image e7c336dc-410a-11e5-9776-85e35eb229fd.png alt="Test Failure" %}

Once good, once failure. *Exactly* once good, once failure. And the two of them
always yielded the same result.

## What's Happening Here?

We quickly found out that QUnit reorders failed tests to the top, i.e. executes
them first on the next run:

```javascript
// `bad` initialized at top of scope
// defer when previous test run passed, if storage is available
bad = QUnit.config.reorder && defined.sessionStorage &&
	+sessionStorage.getItem( "qunit-test-" + this.module.name + "-" + this.testName );

if ( bad ) {
	run();
} else {
	synchronize( run, true );
}
```
(source: [QUnit][1])

So apparently one of the tests that is normally enqueued *before* the flaps was
the culprit. Limiting the list of executed tests to only unit tests didn't
help, the tests still failed/succeeded.

We took a look at each one of them (luckily, it happened quite early, and the
offender was one of the first suspects).  As it turns out, a unit test for an
initializer had been set up, but this specific unfortunately involved starting
the application fully, including running all initializers.  Refactoring to only
run the initializer-under-test the unit tests were green again.

## But the Problem still remains...

We still got failures when an acceptance test ran before one of the failing
unit tests. We had the following facts at hand:

1. it failed during a call to `authorize` an AJAX request
2. it was a unit test with no running application
3. an acceptance test has been run before in the same page

If you want to take a stab at it yourself, here is a [JSBin][2] that replicates
the problem.

Tracking it down, the relevant lines in `authorize` are:

```javascript
 authorize: function(jqXHR, requestOptions) {
	var secureData         = this.get('session.secure');
	var userToken          = secureData[this.tokenAttributeName];
[...]
```

Debugging told us, that in line 3 `secureData` is `undefined`. This made total
sense, since we were not having an active session, and thus also no secure data
in this session.  But why is this function called anyways?

We are doing a mocked AJAX request in this unit test (we are since discussing
whether this is a unit test at all, but this is another topic), and the ajax
prefilter is __still__ attached to JQuery from the last run of the application.

This bug in the amazing `ember-simple-auth` has been fixed and resolved in
version 0.8.1 by testing if `secureData` is present before attempting to access
it.

## What do learn from this?

We were lucky that the lack of encapsulation helped us by failing the tests
early while still in the process of upgrading. Had it not occurred when running
all tests, but only when these tests were executed by themselves, we would have
never known that something just broke.  The issue would have surfaced much
later when one of these tests got rewritten.

It is crucially important that tests are isolated, and we can not rely on the
testing framework to create a sandbox for our tests to run in.  This example
shows the problems we get when state remains in memory after a test has run.
It's probably impossible for a framework to detect all such changes (after all,
the framework itself has to record the outcome of the test *somewhere*). We as
developers have to do this ourselves, by using our best judgement and
experience, but also by trusting the libraries we use.  Tests in the browser
are especially difficult, as we can't have a barrier between the test framework
and our code by design. This is somewhat easier for environments that can spawn
new processes for each test (incurring a significant cost for each test).

Tests are great. They enable us to quickly and automatically execute a lot of
interactions with our code.  Some tests ensure that `sum(2, 3)` actually
returns `5`, while others ensure that clicking a button will change the colour
of the banner on the top.

But we have to keep in mind that tests are not magical, they work with the same
limitations as regular code. We as developers of the tests are responsible to
make sure that now state leaks between tests. Frameworks can help us, but it is
our job in the end.

[1]: https://github.com/jquery/qunit/blob/master/src/test.js#L257
[2]: http://emberjs.jsbin.com/qinuka/2/edit?js,output
