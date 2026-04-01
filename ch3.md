# Chapter 3: Vanilla Algebra

// Introduce  addition rules and operations
```
a + b = b + a
a + 0 = a
(a + b) + c = a + (b + c)
```

Those are laws. That's an algebra. You've been doing this since you were ten.

Let's be precise about what we have:

```
type Integer

(+) :: Integer → Integer → Integer
```

And the laws:

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

That's it. Simple, familiar, complete.

Now add multiplication:

```
(*) :: Integer → Integer → Integer
```

What laws does `*` obey? Write them down.

You probably got commutativity and associativity again. And:

```
a * 1 = a        -- identity
a * 0 = 0        -- annihilation
```

And the relationship between `+` and `*`:

```
a * (b + c) = (a * b) + (a * c)    -- distributivity
```

Notice something: the laws don't just describe individual operations — they describe how operations *relate to each other*. That's where things get interesting.

---

## What About Division?

Let's add division:

```
(/) :: Integer → Integer → Integer
```

We'd expect:

```
(a / b) * b = a
```

*Try a few values. Does it hold?*

`10 / 2 * 2 = 10` ✓  
`9 / 3 * 3 = 9` ✓  
`7 / 2 * 2 = ?` ... well, 7/2 = 3 in integer division, so `3 * 2 = 6 ≠ 7` ✗

Hmm. And then:

```
10 / 0 = ?
```

The law breaks entirely. How you respond to this reveals a lot about your design.

---

## Four Ways to Handle It

### 1. Throw an exception

Most languages do this by default. Division by zero crashes.

The problem: **the law doesn't hold at the boundary**. Your algebra works fine until it doesn't, and you find out at runtime.

### 2. Return a special value (`NaN`, `Infinity`)

IEEE floating point takes this approach. `1.0 / 0.0 = Infinity`.

Looks clever. But:

```
NaN == NaN    -- FALSE
```

Equality itself is now broken. `NaN ≠ NaN` violates the most fundamental law of all — that everything equals itself. The algebra is silently corrupted.

### 3. Return `Maybe Integer`

```
(/) :: Integer → Integer → Maybe Integer
```

Honest. Division might fail, and the type says so. `Nothing` when dividing by zero, `Just n` otherwise.

But now the law has changed shape:

```
(a / b) >>= (* b) = Just a
```

And you've introduced an asymmetry — division takes `Integer` but returns `Maybe Integer`. That's a little awkward. You have to unwrap before you can use the result.

### 4. Lift the whole type

What if division lives in `Maybe Integer` all the way through?

```
(/) :: Maybe Integer → Maybe Integer → Maybe Integer
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

> **The right type is the one where your laws hold everywhere.**

`Integer` was the wrong type for division. `Maybe Integer` is the right one.

This is one of the most important decisions in ADD — before you write a single operation, ask:

*What type makes my laws hold, without exceptions?*

Get the type right and the laws follow naturally. Get it wrong and you spend forever patching edge cases.

---

## What We Learned

From one familiar example, we have the skeleton of the whole process:

1. **Pick a type** — `Integer`, `Maybe Integer`
2. **Pick operations** — `+`, `*`, `/`
3. **Write laws** — commutativity, identity, associativity, inverse
4. **Check the boundaries** — where do the laws break?
5. **Fix the type** — until the laws hold everywhere

Next, let's try the same process on something less mathematical — and see how far it gets us.
