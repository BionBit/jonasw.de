---
title: C++14 on Travis CI with CMake
date: 2015-07-22 11:20:00
category: develop
---

I'm developing a small tool as a side project, and decided to give C++ another spin.
The recent standard C++14 has gained enough attention and pretty widespread compiler adoption
already, so I thought it is a no-issue to be able to compile and test on
the awesome
[Travis CI](https://travis-ci.org) using both GCC and Clang. I was soooo wrong...
Here I will give you some pointers (hehe, pun...) on how to get your C++14 code to compile.

## GCC/Clang versions

Travis CI gives you a Ubuntu Precise with developer tools installed. Unfortunately, Precise
was released three years ago, and does not receive new versions of the two most commonly
used compilers. The version of CLang is fixed to 3.4, and GCC is set to 4.6.3.

Before the introduction of 
[container based infrastructure](http://docs.travis-ci.com/user/workers/container-based-infrastructure/)
we were able to install new versions by executing `sudo apt-get install -y g++`
or similar. If we want to have faster startup times and other benefits we have to refrain from using `sudo`.

To remedy this Travis CI introduced the [APT addon](http://docs.travis-ci.com/user/apt/). With this,
we can add packet sources and install packages declaratively:

```yaml
addons:
	apt:
		sources:
			- llvm-toolchain-precise
			- ubuntu-toolchain-r-test
		packages:
			- clang-3.7
			- g++-5
			- gcc-5
```

With this snippet at the top level of a `travis.yml` file we will get CLang with version 3.7 and
GCC/G++ with version 5 before the scripts in the same file are started. We have to keep in mind
though that $CC is **not** changed to the new executables.

## CMake integration

CMake is a tool that generates build scripts for multiple backends, including 'traditional'
Makefiles. It is able to detect the configured compiler and write it into the Makefile.
It is also possible to detect support for standards, and switch to them at compile time.
Firstly, we want to forward the compiler that Travis gives us to CMake, but we want
to use the new versions that we installed above:

```yaml
install:
	- if [ "$CXX" = "g++" ]; then export CXX="g++-5" CC="gcc-5"; fi
	- if [ "$CXX" = "clang++" ]; then export CXX="clang++-3.7" CC="clang-3.7"; fi
```

In theory, it is possible to require a certain support level that a compiler supports,
and set the standard on the command line declaratively by CMake like this:

```coffeescript
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED on)
```

This does work on my local development machine, adding a `-std=c++14` to the generated command.
However, for reasons I can't understand this does not work on Travis CI, so I went back
to just specifiy the standard manually:

```coffeescript
 set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
 ```

## Conclusion

With these settings in place it is possible to compile code correctly.
It took me a while to get this up and running, but now it's running smoothly.


