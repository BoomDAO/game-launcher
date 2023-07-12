# Itertools

A library with utility functions and data types for creating efficient iterators in Motoko. This library is inspired by the itertools libraries in both [python](https://github.com/more-itertools/more-itertools) and [rust](https://github.com/rust-itertools/itertools).

## Documentation 
For a complete list of functions and data types, see the [Itertools documentation](https://natlabs.github.io/Itertools/index.html)

Demo: https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=1138180896

## Getting started

 To get started, you'll need to import the `Iter` module from both the base library and this one.

 ```motoko
     import Iter "mo:base/Iter";
     import Itertools "mo:itertools/Iter";
 ```
 
 Converting data types to iterators is the next step.
 - Array
     - `[1, 2, 3, 4, 5].vals()`
     - `Iter.fromArray([1, 2, 3, 4, 5])`


 - List
     - `Iter.fromList(list)`


 - Text
     - `"Hello, world!".chars()`
     - `Text.split("a,b,c", #char ',')`
 
 - Buffer
   - `Buffer.toArray(buffer).vals()`
  

 For conversion of other data types to iterators, you can look in the [base library](https://internetcomputer.org/docs/current/references/motoko-ref/array) for the specific data type's documentation.


 Here are some examples of using the functions in this library to create simple and 
 efficient iterators for solving different problems:

 - An example, using `range` and `sum` to find the sum of values from 1 to 25:
 
 ```motoko
     let range = Itertools.range(1, 25 + 1);
     let sum = Itertools.sum(range);

     assert sum == ?325;
 ```


 - Splitting an array into chunks of size 3:

 ```motoko
     let vals = [1, 2, 3, 4, 5, 6].vals();
     let chunks = Itertools.chunks(vals, 3);

     assert Iter.toArray(chunks) == [[1, 2, 3], [4, 5, 6]];
 ```

 - Finding the difference between consecutive elements in an array:

 ```motoko
     let vals = [5, 3, 3, 7, 8, 10].vals();
     
     let tuples = Itertools.slidingTuples(vals);
     // Iter.toArray(tuples) == [(5, 3), (3, 3), (3, 7), (7, 8), (8, 10)]
     
     let diff = func (x : (Int, Int)) : Int { x.1 - x.0 };
     let iter = Iter.map(tuples, diff);
 
     assert Iter.toArray(iter) == [-2, 0, 4, 1, 2];
 ```

## Contributing
Any contributions to this library are welcome. 
Ways you can contribute:
- Fix a bug or typo
- Improve the documentation
- Make a function more efficient
- Suggest a new function to add to the library

## Tests
- Download and Install [vessel](https://github.com/dfinity/vessel) 
- Run `make test` 

## Modules and Functions
### PeekableIter
| | |
|-|-|
| Iter to PeekableIter | [fromIter](https://natlabs.github.io/Itertools/PeekableIter.html#fromIter) |


### Deiter - (Double-Ended Iterator)
| | |
|-|-|
| Main Methods |  [reverse](https://natlabs.github.io/Itertools/Deiter.html#reverse), [range](https://natlabs.github.io/Itertools/Deiter.html#range), [intRange](https://natlabs.github.io/Itertools/Deiter.html#intRange), |
| Collection to DeIter | [fromArray](https://natlabs.github.io/Itertools/Deiter.html#fromArray), [fromArrayMut](https://natlabs.github.io/Itertools/Deiter.html#fromArrayMut), [fromDeque](https://natlabs.github.io/Itertools/Deiter.html#fromDeque) |
| DeIter to Collection | [toArray](https://natlabs.github.io/Itertools/Deiter.html#toArray), [toArrayMut](https://natlabs.github.io/Itertools/Deiter.html#toArrayMut), [toDeque](https://natlabs.github.io/Itertools/Deiter.html#toDeque) |


### Iter
| | |
|-|-|
| Augmenting | [accumulate](https://natlabs.github.io/Itertools/Iter.html#accumulate),  [add](https://natlabs.github.io/Itertools/Iter.html#add), [countAll](https://natlabs.github.io/Itertools/Iter.html#countAll), [enumerate](https://natlabs.github.io/Itertools/Iter.html#enumerate), [flatten](https://natlabs.github.io/Itertools/Iter.html#flatten), [flattenArray](https://natlabs.github.io/Itertools/Iter.html#flattenArray), [intersperse](https://natlabs.github.io/Itertools/Iter.html#intersperse), [mapEntries](https://natlabs.github.io/Itertools/Iter.html#mapEntries), [mapWhile](https://natlabs.github.io/Itertools/Iter.html#mapWhile),[runLength](https://natlabs.github.io/Itertools/Iter.html#runLength),[pad](https://natlabs.github.io/Itertools/Iter.html#pad), [padWithFn](https://natlabs.github.io/Itertools/Iter.html#padWithFn), [partitionInPlace](https://natlabs.github.io/Itertools/Iter.html#partitionInPlace), [prepend](https://natlabs.github.io/Itertools/Iter.html#prepend), [successor](https://natlabs.github.io/Itertools/Iter.html#successor), [uniqueCheck](https://natlabs.github.io/Itertools/Iter.html#uniqueCheck) |
| Combining | [interleave](https://natlabs.github.io/Itertools/Iter.html#interleave), [interleaveLongest](https://natlabs.github.io/Itertools/Iter.html#interleaveLongest), [merge](https://natlabs.github.io/Itertools/Iter.html#merge), [kmerge](https://natlabs.github.io/Itertools/Iter.html#kmerge), [zip](https://natlabs.github.io/Itertools/Iter.html#zip), [zip3](https://natlabs.github.io/Itertools/Iter.html#zip3), [zipLongest](https://natlabs.github.io/Itertools/Iter.html#zipLongest) |
| Combinatorics | [combinations](https://natlabs.github.io/Itertools/Iter.html#combinations), [cartesianProduct](https://natlabs.github.io/Itertools/Iter.html#cartesianProduct), [permutations](https://natlabs.github.io/Itertools/Iter.html#permutations) |
| Look ahead | [peekable](https://natlabs.github.io/Itertools/Iter.html#peekable), [spy](https://natlabs.github.io/Itertools/Iter.html#spy) |
| Grouping | [chunks](https://natlabs.github.io/Itertools/Iter.html#chunks), [chunksExact](https://natlabs.github.io/Itertools/Iter.html#chunksExact), [groupBy](https://natlabs.github.io/Itertools/Iter.html#groupBy), [splitAt](https://natlabs.github.io/Itertools/Iter.html#splitAt), [tuples](https://natlabs.github.io/Itertools/Iter.html#tuples), [triples](https://natlabs.github.io/Itertools/Iter.html#triples), [unzip](https://natlabs.github.io/Itertools/Iter.html#unzip), |
| Repeating | [cycle](https://natlabs.github.io/Itertools/Iter.html#cycle), [repeat](https://natlabs.github.io/Itertools/Iter.html#repeat),  |
| Selecting | [find](https://natlabs.github.io/Itertools/Iter.html#find), [findIndex](https://natlabs.github.io/Itertools/Iter.html#findIndex), [findIndices](https://natlabs.github.io/Itertools/Iter.html#findIndices), [mapFilter](https://natlabs.github.io/Itertools/Iter.html#mapFilter),  [max](https://natlabs.github.io/Itertools/Iter.html#max), [min](https://natlabs.github.io/Itertools/Iter.html#min), [minmax](https://natlabs.github.io/Itertools/Iter.html#minmax), [nth](https://natlabs.github.io/Itertools/Iter.html#nth), [nthOrDefault](https://natlabs.github.io/Itertools/Iter.html#nthOrDefault), [skip](https://natlabs.github.io/Itertools/Iter.html#skip), [skipWhile](https://natlabs.github.io/Itertools/Iter.html#skipWhile),  [stepBy](https://natlabs.github.io/Itertools/Iter.html#stepBy), [take](https://natlabs.github.io/Itertools/Iter.html#take), [takeWhile](https://natlabs.github.io/Itertools/Iter.html#takeWhile), [unique](https://natlabs.github.io/Itertools/Iter.html#unique) |
| Sliding Window |[slidingTuples](https://natlabs.github.io/Itertools/Iter.html#slidingTuples), [slidingTriples](https://natlabs.github.io/Itertools/Iter.html#slidingTriples) |
| Summarising | [all](https://natlabs.github.io/Itertools/Iter.html#all), [any](https://natlabs.github.io/Itertools/Iter.html#any), [count](https://natlabs.github.io/Itertools/Iter.html#count), [equal](https://natlabs.github.io/Itertools/Iter.html#equal), [fold](https://natlabs.github.io/Itertools/Iter.html#fold), [mapReduce]( https://natlabs.github.io/Itertools/Iter.html#mapReduce), [notEqual](https://natlabs.github.io/Itertools/Iter.html#notEqual), [isSorted](https://natlabs.github.io/Itertools/Iter.html#isSorted), [isSortedDesc](https://natlabs.github.io/Itertools/Iter.html#isSortedDesc), [isPartitioned](https://natlabs.github.io/Itertools/Iter.html#isPartitioned), [isUnique](https://natlabs.github.io/Itertools/Iter.html#isUnique), [product](https://natlabs.github.io/Itertools/Iter.html#product), [reduce](https://natlabs.github.io/Itertools/Iter.html#reduce), [sum](https://natlabs.github.io/Itertools/Iter.html#sum), |
| Collection to Iter | [fromArraySlice](https://natlabs.github.io/Itertools/Iter.html#fromArraySlice), [fromTrieSet](https://natlabs.github.io/Itertools/Iter.html#fromTrieSet) | 
| Iter to Collection | [toBuffer](https://natlabs.github.io/Itertools/Iter.html#toBuffer), [toDeque](https://natlabs.github.io/Itertools/Iter.html#toDeque), [toText](https://natlabs.github.io/Itertools/Iter.html#toText), [toTrieSet](https://natlabs.github.io/Itertools/Iter.html#toTrieSet) |
| Others | [inspect](https://natlabs.github.io/Itertools/Iter.html#inspect), [range](https://natlabs.github.io/Itertools/Iter.html#range), [intRange](https://natlabs.github.io/Itertools/Iter.html#intRange),  [ref](https://natlabs.github.io/Itertools/Iter.html#ref), [sort](https://natlabs.github.io/Itertools/Iter.html#sort), [tee](https://natlabs.github.io/Itertools/Iter.html#tee),          |
