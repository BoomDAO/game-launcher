import Prim "mo:⛔";
import B "../src/StableBuffer";
import I "mo:base/Iter";
import O "mo:base/Option";
import Array "mo:base/Array";

// test repeated growing
let a = B.initPresized<Nat>(3);
for (i in I.range(0, 123)) {
  B.add(a, i);
};
for (i in I.range(0, 123)) {
  assert (B.get(a, i) == i);
};


// test repeated appending
let b = B.initPresized<Nat>(3);
for (i in I.range(0, 123)) {
  B.append(b, a);
};

// test repeated removing
for (i in I.revRange(123, 0)) {
  switch(B.removeLast(a)) {
    case null { assert false };
    case (?el) { assert el == i };
  }
};
assert O.isNull(B.removeLast(a));

func natArrayIter(elems:[Nat]) : I.Iter<Nat> = object {
  var pos = 0;
  let count = elems.size();
  public func next() : ?Nat {
    if (pos == count) { null } else {
      let elem = ?elems[pos];
      pos += 1;
      elem
    }
  }
};

func natVarArrayIter(elems:[var Nat]) : I.Iter<Nat> = object {
  var pos = 0;
  let count = elems.size();
  public func next() : ?Nat {
    if (pos == count) { null } else {
      let elem = ?elems[pos];
      pos += 1;
      elem
    }
  }
};

func natIterEq(a:I.Iter<Nat>, b:I.Iter<Nat>) : Bool {
   switch (a.next(), b.next()) {
     case (null, null) { true };
     case (?x, ?y) {
       if (x == y) { natIterEq(a, b) }
       else { false }
     };
     case (_, _) { false };
   }
};

// regression test: buffers with extra space are converted to arrays of the correct length
do {
  let bigLen = 100;
  let len = 3;
  let c = B.initPresized<Nat>(bigLen);
  assert (len < bigLen);
  for (i in I.range(0, len - 1)) {
    B.add(c, i);
  };
  assert (B.size<Nat>(c) == len);
  assert (B.toArray(c).size() == len);
  assert (natIterEq(B.vals(c), natArrayIter(B.toArray(B.clone<Nat>(c)))));
  assert (B.toVarArray(c).size() == len);
  assert (natIterEq(B.vals(c), natVarArrayIter(B.toVarArray(B.clone(c)))));
};

// regression test: initially-empty buffers grow, element-by-element
do {
  let c = B.initPresized<Nat>(0);
  assert (B.toArray(c).size() == 0);
  assert (B.toVarArray(c).size() == 0);
  B.add(c, 0);
  assert (B.toArray(c).size() == 1);
  assert (B.toVarArray(c).size() == 1);
  B.add(c, 0);
  assert (B.toArray(c).size() == 2);
  assert (B.toVarArray(c).size() == 2);
};

// test fromArray
do {
  let arr = [1,2,3,4,5];
  let d = B.fromArray<Nat>(arr);
  assert (natIterEq(B.vals<Nat>(d), arr.vals())); 
  assert (B.size<Nat>(d) == arr.size()); 
};

// test init
do {
  let e = B.init<Nat>();
  assert (B.toArray(e).size() == 0);
  assert (B.toVarArray(e).size() == 0);
  B.add(e, 0);
  assert (B.toArray(e).size() == 1);
  assert (B.toVarArray(e).size() == 1);
  B.add(e, 1);
  B.add(e, 2);
  assert (B.toArray(e).size() == 3);
  assert (B.toVarArray(e).size() == 3);
  assert (e.elems.size() == 4);
}
