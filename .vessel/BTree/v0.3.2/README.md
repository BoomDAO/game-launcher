# StableHeapBTreeMap

A functional, heap-based [BTree](https://en.wikipedia.org/wiki/B-tree) data structure written in Motoko

## API Documentation

Full API documentation for this library can be found at https://canscale.github.io/StableHeapBTreeMap/BTree.html


## Usage
Install vessel and ensure this is included in your package-set.dhall and vessel.dhall
```
import BTree "mo:btree/BTree";
...
// initialize
let t = BTree.init<Text, Nat>(?32); // 32 is the order, or the size of each BTree node

// initialize from an array or buffer (similar methods for toArray/toBuffer)
let t = BTree.fromArray<Text, Nat>(32, Text.compare, array);
let t = BTree.fromBuffer<Text, Nat>(32, Text.compare, buffer);

// insert (write)
let originalValue = BTree.insert<Text, Nat>(t, Text.compare, "John", 52);

// paginate through a collection in ascending order grab first 10 and the next key
let { results; nextKey } = BTree.scanLimit<Text, Nat>(t, Text.compare, "A", "Z", #fwd, 10);

// get min element
let minElement = BTree.min<Text, Nat>(t);
```
... and much more, head to the [docs](https://canscale.github.io/StableHeapBTreeMap/BTree.html) to see the full API.

## License

StableHeapBTreeMap is distributed under the terms of the Apache License (Version 2.0).

See LICENSE for details.
