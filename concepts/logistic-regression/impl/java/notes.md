Each step makes two passes over the 150 training rows. The first adds every
row's error times its inputs into a fresh `double[] gradient`; the second
moves the weights in place. That's safe only because the whole gradient
exists first: update inside the row loop and the intercept comes out
0.758788 instead of 0.753594.

`readColumn` returns strings here, since `split` holds words, and each row
is checked with `.equals("train")`, because `==` would compare the `String`
objects. The JDK has no regression or optimizer, so there was no built-in
to skip; `Math.exp` and `Math.log` do the rest.
