# Explore rank issue of G matrix

#math/linear-algebra/matrix/sparse-matrix/rank

## Structural rank

There is a MATLAB function `sprank` introduced in R2006a:
> The structural rank of a matrix is the maximum rank of all matrices w/ the same nonzero pattern.

→ it has an important feature that 

> A matrix has full structural rank *if it can be permuted so that diagonal has no zero entries*

in terms of the usage for my investigation, since in many case, the measurement matrix G is too large to compute its rank by `rank(G)`, I can only check its structural rank to get an upper bound, since

> the structural rank is an upper bound on the rank of a matrix, i.e., `sprank(A) >= rank(full(A))`

the implementation of `sprank` is 

``` matlab
r = sum(dmperm(A)>0);
```

In the comment of the above code, it states that 

> in exact arithmetic `sprank(A) == rank(full(sprandn(A)))` with probability one.

Sparse matrix in MATLAB is just *association* (in Mathematica)

``` matlab
>> A = [1 0 2 0
     2 0 4 0];
>> A

A =

     1     0     2     0
     2     0     4     0

>> rank(A)

ans =

     1

>> sA = sparse(A)

sA =

   (1,1)        1
   (2,1)        2
   (1,3)        2
   (2,3)        4

>> rs = sprank(sA)

rs =

     2
```

-> for this matrix, the structural rank is 2 *since two of the columns are nonzero*. But the actual rank of the matrix is 1 since the columns are multiples of each other.

-> however, the structural rank is NOT the count of non-zero columns

``` matlab
>> A = [1, 0, 2, 0, 3; 2, 0, 4, 0, 6]

A =

     1     0     2     0     3
     2     0     4     0     6

sA = sparse(A);

>> sprank(sA)

ans =

     2

>> 
```

-> given the definition, "the structural rank of a matrix is the **maximum** rank of all matrices w/ the **same nonzero pattern**" -> there are 3 non-zero columns for this 2-by-5 matrix, so the possible maximum rank is apparently 2 (as long as at least 2 columns are nonzero).

## Dulmage-Mendelsohn decomposition

Digging the internal of structural rank calculation

> `p = dmperm(A)` finds a *vector* `p` such that `p(j) = i`  if column `j` is **matched** to row `i`, or zero if column j is unmatched.

→ The structural rank of A is `sprank(A) = sum(p>0)`

> If A is a reducible matrix, the linear system `Ax = b` can be solved by permuting `A` to a block upper triangular form, w/ irreducible diagonal blocks, and then performing block back substitution.

→ see [2022-02-06-dmperm](./2022-02-06-dmperm.md) for more info.

## Appendix

About sparse matrix related functions in MATLAB → `R = sprandn(S)`  creates a sparse matrix that has the same *sparsity pattern* (i.e., the indexes of the non-zeros are EXACTLY the SAME ) as the matrix S, but w/ normally distributed random entries w/ mean 0 and variance 1

>The reciprocal condition number is a scale-invariant measure of how close a given matrix is to the set of singular matrices.

## TODO

MATLAB的帮助文档里有一个"Sparse Matrices"专题，先把它搞透 → [Documentation Home > MATLAB > Mathematics > Sparse Matrices]

