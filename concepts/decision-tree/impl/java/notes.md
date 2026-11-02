The tree is a sealed interface, `Node`, that permits exactly two records:
`Leaf` holds a prediction, and `Split` holds a feature, a threshold, and
two children. Records write their own constructor and accessors, and their
fields are final. Because `Node` is sealed, `predict` can `switch` on a
node with record patterns and no `default`; drop the `Leaf` case and javac
stops with "the switch expression does not cover all possible input
values". `grow` calls itself on each side. Each feature's values go into a
`TreeSet`, which sorts them and drops repeats, and we try the midpoint of
each neighboring pair. The JDK has no decision tree, so there was no
built-in to skip.
