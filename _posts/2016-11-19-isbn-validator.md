---
title: ISBN Validator
categories: develop haskell
---


ISBNs (International Standard Book Numbers) are a standardized way to identify
books internationally. Historically, they consisted of *ten* digits, with nine
of them identifying the book and one serving as control digit. The presence of
a control digit ensures (to some extent) that the buyer receives the book she
ordered and not something totally different.

This post describes a small module written in Haskell that takes a `String` and
checks whether the control digit is properly calculated. It tries to guess
which algorithm is to be used, depending on the length of the `String`.

```haskell
module ISBN (isValid) where
```

This implementation makes heavy use of the composition functionalities offered
by the
[`Control.Arrow`](hackage.haskell.org/package/base/docs/Control-Arrow.html)
module in the `base` package. If you never developed with Arrows before, check
it out, it's a lot of fun!

```haskell
import Control.Arrow ((***), (&&&), (>>>), first, second)
import Control.Monad (unless)
import Data.Char (isDigit, digitToInt, intToDigit)
```

In the spirit of Test Driven Development we first define a set of `String`s
that either are valid ISBNS (with correct length and control digit), or are not
valid. After the implementation we will know that the algorithm behaves
correctly at least in these cases.

```haskell
test1 =       isValid "0136091814"
test2 = not $ isValid "0136091812"
test3 =       isValid "9780136091813"
test4 = not $ isValid "9780136091817"
test5 =       isValid "123456789X"
```

It is totally fine to separate components of an ISBN with spaces or dashes to
improve readability and communicability. All the following variants of ISBNs
are also valid:

```haskell
test6 = all isValid
  [ "0471958697"
  , "0 471 60695 2"
  , "0-470-84525-2"
  , "0-321-14653-0"
  , "9780470059029"
  , "978 0 471 48648 0"
  , "978-0596809485"
  , "978-0-13-149505-0"
  , "978-0-262-13472-9"
  ]
```

Cleaning ISBNs
--------------

The latter test cases included some decorative spaces and dashes. It's probably
best to remove them as early as possible. The following function does just
that: It removes all characters which are not allowed in a ISBN.

```haskell
cleanISBN :: String -> String
cleanISBN = filter isAllowed
```

Which characters are not allowed? It's easier to say which *are* allowed: the
upper case `X` and anything that is a digit. Otherwise, the helper function
returns `False` and this function in total rejects the letter.

```haskell
  where isAllowed 'X' = True
        isAllowed x
          | isDigit x = True
          | otherwise = False
```

Just to be sure we add some test cases that demonstrate the functionality:

```haskell
test7 = cleanISBN "123456789X" == "123456789X"
test8 = cleanISBN "asdb$$$555" == "555"
```

Splitting an ISBN
-----------------

Later, it will be beneficial to split an ISBN `String` into two parts: A list
of integers (`[Int]`) containing the payload digits and the control digit of
type `Char` (to accomodate the possible 'X'). The `splitISBNIntoParts` function
does this:

```haskell
splitISBNIntoParts :: String -> ([Int], Char)
splitISBNIntoParts x = (map digitToInt *** head) (splitAt (length x - 1) x)
```

This makes use of Arrow-style function composition. It splits the given string into a pair of substrings, the first containing all characters but the last, and the second containing just the last character. This pair is passed to an Arrow (created using the `(***)` combinator) that transforms the first component using `map digitToInt` (parsing each entry in the list into a number) and the second component into the first element of the list.

Validating an ISBN-10
---------------------

An ISBN-10 control digit is calculated by multiplying each digit with its one-based index and taking the remainder from the integer division by eleven. For example:

**ISBN**: `0471958697`

     ( (0 × 1) + (4 × 2) + (7 × 3) + (1 × 4)
     + (9 × 5) + (5 × 6) + (8 × 7) + (6 × 8) + (9 × 9)) mod 11
     = 293 mod 11
     = 7

The `modulo-11` operation may yield a `10`, in which case the letter `X` is used instead. The following functions encode this algorithm.

Firstly, we have to guess whether a given `String` might be an ISBN-10. Although it is only a neccessary condition that the given `String` has length 10, no valid ISBN-13 can ever have this length which makes it 'good enough':

```haskell
mightBeISBN10 :: String -> Bool
mightBeISBN10 isbn = length isbn == 10
```

As an aside: This function can easily be written in point-free notation, but it is up to the reader to decide whether this improves readability:

```haskell
mightBeISBN10' :: String -> Bool
mightBeISBN10' = (==) 10 . length
```

Or, using Arrows:

```haskell
mightBeISBN10'' :: String -> Bool
mightBeISBN10'' = length >>> (==) 10
```

Calculating the control digit from the payload digits is done in steps, according to the algorithm. The function is expressed using Arrow functions:

```haskell
calculateISBN10ControlDigit :: [Int] -> Char
calculateISBN10ControlDigit =
```

Each digit is combined with the corresponding number from the range `[1..9]` by using standard integer multiplication. The function

    zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]

fits perfectly in this case. The multiplication of type

    Num a => a -> a -> a

specializes the `zipWith` to operation on a list of numbers, and the given range populates the multipliers for each digit.

```haskell
  zipWith (*) [1..9]
```

The Arrow combinator `(>>>)` is used to build an Arrow that first applies the parameter to the left function and passes the result to the right one. This is very similar to the standard function composition operator `(.)`, with the difference in the order the parameters are evaluated: `(.)` in the 'standard mathematical`order from right-to-left, and`(&gt;&gt;&gt;)\` from left-to-right.

The `sum` functions takes a list of numbers and gives the sum of it:

```haskell
      >>> sum
```

The result of this sum is to be taken modulo 11. The `mod` function provided by Haskell is flipped (giving a function that gives the first parameter as second to the original version, and vice versa) and the result partially applied to 11.

```haskell
  >>> flip mod 11
```

In the end, the `stringifyISBNDigit` converts the result into a `Char` (yielding 'X' when the result is 10, otherwise the digit itself).

```haskell
  >>> stringifyISBNDigit
   where stringifyISBNDigit :: Int -> Char
         stringifyISBNDigit 10  = 'X'
         stringifyISBNDigit x   = intToDigit x
```

This completes the control digit calculation function. The only thing left is to combine these parts into a validation function function (this function assumes the ISBN has already been cleaned and is of correct length):

```haskell
isValidISBN10 :: String -> Bool
isValidISBN10 isbn = givenControlDigit == calculateISBN10ControlDigit payloadDigits
  where (payloadDigits, givenControlDigit) = splitISBNIntoParts isbn
```

Validating an ISBN-13
---------------------

The new standard intended to fit into the EAN-13 system uses the same nine payload digits prefixed with `978` and a different algorithm to calculate the control digit. The algorithm instead uses a repetition of the numbers 1 and 3 for the multipliers and uses a more complex operation for the final reduction: The control digit `c` for the sum of the weighted payload digits `p` is calculated by `c = (10 - (p mod 10)) mod 10`. For example:

**ISBN-13**: `9780470059029`

    p = (9 × 1) + (7 × 3) + (8 × 1) + (0 × 3)
      + (4 × 1) + (7 × 3) + (0 × 1) + (0 × 3)
      + (5 × 1) + (9 × 3) + (0 × 1) + (2 × 3)
      = 101
    c = (10 - (101 mod 10)) mod 10
      = (10 - 1) mod 10
      = 9 mod 10
      = 9

But first, we define the guessing function. It returns 'OK' when the given String a) is of length 13 and b) begins with `978`:

```haskell
mightBeISBN13 :: String -> Bool
mightBeISBN13 isbn@('9' : '7' : '8' : _) = length isbn == 13
mightBeISBN13 _                          = False
```

Afterwards, we are able to define the calculation of the control digit in Haskell:

```haskell
calculateISBN13ControlDigit :: [Int] -> Char
calculateISBN13ControlDigit =
```

Similar to the ISBN-10 version, we zip the digits together with a list of
multipliers. This time they are not created by a range, but by an infinite
cycle of 1s and 3s. The `zipWith` function stops zipping as soon as the shorter
list has run out of elements, so using an infinite list for one is totally
acceptable.

```haskell
  zipWith (*) (cycle [1, 3])
```

Again, we take the sum of the single components:

```haskell
  >>> sum
```

The final digit is calculated by taking it modulo 10, subtract it from 10 and take the modulo 10 again. Afterwards, it is converted to a string.

```haskell
  >>> moduloTen >>> tenMinus >>> moduloTen
  >>> intToDigit
    where moduloTen = flip mod 10
          tenMinus  =      (-) 10
```

Plugging it together:

```haskell
isValidISBN13 :: String -> Bool
isValidISBN13 isbn = givenControlDigit == calculateISBN13ControlDigit payloadDigits
  where (payloadDigits, givenControlDigit) = splitISBNIntoParts isbn
```

Conclusion
----------

We now have functions that guess the kind of ISBN, and functions to clean and
validate it according to its guessed kind. Finally, we can create the `isValid`
function providing a nice interface by composition:

```haskell
isValid :: String -> Bool
isValid = isCleanedISBNValid . cleanISBN
  where
      isCleanedISBNValid isbn
          | mightBeISBN13 isbn = isValidISBN13 isbn
          | mightBeISBN10 isbn = isValidISBN10 isbn
          | otherwise         = False
```

The `main` function marks the end of this program. It just tests whether all
test cases run successfully. Check yourself if there are any mistakes, this
post is written as Literate Haskell.

```haskell
main :: IO ()
main = unless (and [test1, test2, test3, test4, test5, test6, test7, test8]) $ fail "Test cases failed"
```
