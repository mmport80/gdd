# Chapter 3: Vanilla Algebra

// Introduce addition rules and operations

```
a + b = b + a
a + 0 = a
(a + b) + c = a + (b + c)
```

// Haskell type definition

```
type Integer

(+) :: Integer → Integer → Integer
```

The rules are instances of well known properties:

**Commutativity** — order doesn't matter:
```
a + b = b + a
```

**Identity** — adding nothing changes nothing:
```
a + 0 = a
```

**Associativity** — grouping doesn't matter:
```
(a + b) + c = a + (b + c)
```

**Inverse** — everything can be undone:
```
a + (-a) = 0
```

That's it. Simple, familiar.

Now add multiplication:

```
(*) :: Integer → Integer → Integer
```

What laws does `*` obey?

Commutativity and associativity again. And also:

```
a * 1 = a        -- identity
a * 0 = 0        -- annihilation
```

And the relationship between `+` and `*`:

```
a * (b + c) = (a * b) + (a * c)    -- distributivity
```

Notice something: the rules don't just describe individual operations — they describe how operations *relate to each other*.

---

## What About Division?

Let's add division:

```
(/) :: Integer → Integer → Integer
```

We might expect this rule:

```
(a / b) * b = a
```

which is the called the 'inverse' property.


## Remainder Problem

*Try a few values. Does it hold?*

`10 / 2 * 2 = 10` ✓  
`9 / 3 * 3 = 9` ✓  
`7 / 2 * 2 = ?` ... well, 7/2 = 3 in integer division, so `3 * 2 = 6 ≠ 7` ✗

We cannot depend on inversion. How about switching from Integer to something else?

### Float Problem

Float numbers include decimals. Intuitively they should account for any remainder.

`0.1 + 0.2 = 0.30000000000000004`

But they may not always be precise enough, leading to breaks in equality.

### Rational Solution

Rational numbers preserve the numerator and denomenator information throughout each operation.

`7 / 2 * 2 = 7`

You might ask why fulfilling the inversion property is so important?

If we look back at each of the previous attempts at division, none actually followed the aim of the property: to divide equally. The remainders got in the way.

The properties aren't just nice-to-haves, they ensure our operations do what we intend them to.

## Four Ways to Handle Division by Zero

Hmm. And then:

```
10 / 0 = ?
```

this inversion is really troublesome, eh? Luckily programmers have many ways to patch this.

### 1. Throw an exception

Most languages do this by default. Division by zero crashes.

The problem: **the law doesn't hold at the boundary**. Your algebra works fine until it doesn't, and you find out at runtime.

### 2. Return a special value (`NaN`, `Infinity`)

`1.0 / 0.0 = Infinity` is not very helpful.


`1.0 / 0.0 = NaN` is another oddity. The IEEE specifies that `Nan /= NaN`, which is strange.

### 3. Return `Maybe Rational`

```
(/) :: Rational → Rational → Maybe Rational
```

Honest. Division might fail, and the type says so. `Nothing` when dividing by zero, `Just n` otherwise.

But now the law has changed shape:

```
(a / b) >>= (* b) = Just a
```

And you've introduced an asymmetry — division takes `Rational` but returns `Maybe Rational`. That's awkward. You have to unwrap before you can use the result, and lose function composition.

### 4. Lift the whole type

What if division lives in `Maybe Rational` all the way through?

```
(/) :: Maybe Rational → Maybe Rational → Maybe Rational
```

Now `Nothing` is just a value like any other — it **propagates**:

```
Nothing / x = Nothing
x / Nothing = Nothing
```

And the law holds uniformly:

```
(a / b) * b = a
```

...for all `a` and `b`, including the bad cases. No exceptions. No special values. No asymmetry.

---

## Choosing the Right Type

The lesson here isn't really about division. It's this:

> **The right type is the one where your rules work reliably everywhere.**

`Integer` was the wrong type for our simple numerical algebra. `Maybe Rational` is the right one.

---

## What We Learned

From familiar maths, we have the skeleton of the whole process:

1. **Pick a type** — `Maybe Rational`
2. **Pick operations** — `+`, `*`, `/`
3. **Write rules** — commutativity, identity, associativity, inverse, etc.
4. **Check the boundaries** — where do the laws break?
5. **Fix the type** — until the laws hold everywhere

Next, let's try the same process on something less mathematical — and see how far it gets us.
