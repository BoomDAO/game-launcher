/// **A merkle tree**
///
/// This library provides a simple merkle tree data structure for Motoko.
/// It provides a key-value store, where both keys and values are of type Blob.
///
/// ```motoko
/// var t = MerkleTree.empty();
/// t := MerkleTree.put(t, "Alice", "\00\01");
/// t := MerkleTree.put(t, "Bob", "\00\02");
///
/// let w = MerkleTree.reveals(t, ["Alice" : Blob, "Malfoy": Blob].vals());
/// ```
/// will produce
/// ```
/// #fork (#labeled ("\3B…\43", #leaf("\00\01")), #pruned ("\EB…\87"))
/// #fork(#labeled("\41\6C\69\63\65", #leaf("\00\01")), #labeled("\42\6F\62", #pruned("\E6…\E2")))
/// ```
///
/// The witness format is compatible with the [HashTree] used by the Internet Computer,
/// so client-side, the same verification logic can be used.
///
/// Revealing multiple keys at once is supported, and so is proving absence of a key.
///
/// The tree branches on the bits of the keys (i.e. a patricia tree). This means that the merkle
/// tree and thus the root hash is unique for a given tree. This in particular means that insertions
/// are efficient, and that the tree can be reconstructed from the data, independently of the
/// insertion order.
///
/// A functional API is provided (instead of an object-oriented one), so that
/// the actual tree can easily be stored in stable memory.
///
/// [HashTree]: <https://internetcomputer.org/docs/current/references/ic-interface-spec#certificate>

import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Stack "mo:base/Stack";
import Nat8 "mo:base/Nat8";
import SHA256 "mo:sha2/Sha256";
import Dyadic "Dyadic";

module {

  public type Key = Blob;
  public type Path = [Blob];
  public type Value = Blob;

  /// This is the main type of this module: a possibly empty tree that maps
  /// `Key`s to `Value`s.
  public type Tree = LabeledTree;

  type Leaf = { value : Value; leaf_hash : Hash; };
  type LabeledTree = { #leaf : Leaf; #subtree : OT; };

  type OT = ?T;
  type T = {
    // All values in this fork are contained in the `interval`.
    // Moreover, the `left` subtree is contained in the left half of the interval
    // And the `right` subtree is contained in the right half of the interval
    #fork : {
      interval : Dyadic.Interval;
      hash : Hash; // simple memoization of the HashTree hash
      left : T;
      right : T;
    };
    // The value or subtree at a certain label, plus the
    // elements whose keys this is a strict prefix of
    #prefix : {
      key : Key;
      prefix : Prefix; // a copy of the key as array
      here : LabeledTree; // Invariant: never an empty tree
      labeled_hash : Hash; // simple memoization of the labeled leaf HashTree hash
      rest : OT; // Labels that are a suffix of key
      tree_hash : Hash; // simple memoization of the overall HashTree hash
    };
  };

  /// The type of witnesses. This correponds to the `HashTree` in the Interface
  /// Specification of the Internet Computer
  public type Witness = {
    #empty;
    #pruned : Hash;
    #fork : (Witness, Witness);
    #labeled : (Key, Witness);
    #leaf : Value;
  };

  public type Hash = Blob;

  /// Nat8 is easier to work with so far
  type Prefix = [Nat8];

  // Hash-related functions
  func h(b : Blob) : Hash {
    SHA256.fromBlob(#sha256, b);
  };
  func h2(b1 : Blob, b2 : Blob) : Hash {
    let d = SHA256.Digest(#sha256);
    d.writeBlob(b1);
    d.writeBlob(b2);
    d.sum();
  };
  func h3(b1 : Blob, b2 : Blob, b3 : Blob) : Hash {
    let d = SHA256.Digest(#sha256);
    d.writeBlob(b1);
    d.writeBlob(b2);
    d.writeBlob(b3);
    d.sum();
  };

  /// The hashing function for the hash tree
  func hashEmpty()                    : Hash { h("\11ic-hashtree-empty") };
  func hashLeaf(v : Blob)             : Hash { h2("\10ic-hashtree-leaf", v) };
  func hashLabeled(l : Key, s : Hash) : Hash { h3("\13ic-hashtree-labeled", l, s) };
  func hashFork(l : Hash, r : Hash)   : Hash { h3("\10ic-hashtree-fork", l, r) };

  // Functions on Tree (the possibly empty tree)

  /// The root hash of the merkle tree. This is the value that you would sign
  /// or pass to `CertifiedData.set`
  public func treeHash(t : Tree) : Hash {
    labeledTreeHash(t);
  };

  /// Tree construction: The empty tree
  public func empty() : Tree {
    return #subtree null
  };

  /// Tree construction: Inserting a key into the tree.
  /// An existing value under that key is overridden.
  /// This also deletes all keys at all paths that are a
  /// prefix of the given path!
  public func put(t : Tree, ks : Path, v : Value) : Tree {
    putIter(t, ks.vals(), v);
  };

  /// Deleting a key from a tree.
  /// This removes the given key from the tree, independently
  /// of whether there is a value at that label, or a whole subtree.
  /// Will also remove enclosing labels if there is no value left.
  public func delete(t : Tree, ks : Path) : Tree {
    deleteIter(t, ks.vals());
  };

  /// Looking up a value at a key
  ///
  /// This will return `null` if the key does not exist, or if 
  /// there is a subtree (and not a value) at that key.
  public func lookup(t : Tree, ks : Path) : ?Value {
    switch (lookupIter(t, ks.vals())) {
      case (#leaf(v)) { ?(v.value) };
      case (#subtree(_)) { null };
    };
  };

  /// Lookup up all labels at a key. Returns an iterator, so you can use it with
  /// ```
  /// for (k in MerkleTree.labelsAt(t, ["some", "path"))) { … }
  /// ```
  public func labelsAt(t : Tree, ks : Path) : Iter.Iter<Key> {
    switch (lookupIter(t, ks.vals())) {
      case (#leaf(_)) { empty_iter };
      case (#subtree(null)) { empty_iter };
      case (#subtree(?t)) { iterLabels(t)};
    }
  };

  let empty_iter : Iter.Iter<None> = {
    next = func () : ?None { null };
  };

  // Labeled tree (the multi-level trees)

  func labeledTreeHash(s : LabeledTree) : Hash {
    switch s {
      case (#leaf(l)) l.leaf_hash;
      case (#subtree(t)) hashOT(t);
    }
  };

  func hashOT(t : OT) : Hash {
    switch (t) {
      case (null) hashEmpty();
      case (?t) hashT(t);
    }
  };

  // Now on the real T (the non-empty one-level tree)

  func hashT(t : T) : Hash {
    switch t {
      case (#fork(f)) f.hash;
      case (#prefix(l)) l.tree_hash;
    }
  };

  func intervalT(t : T) : Dyadic.Interval {
    switch t {
      case (#fork(f)) { f.interval };
      case (#prefix(l)) { Dyadic.singleton(l.prefix) };
    }
  };

  // Smart contructors (memoize the hashes and other data)

  func mkLeaf (v : Value) : Leaf {
    let leaf_hash = hashLeaf(v);
    { value = v; leaf_hash = leaf_hash}
  };

  func mkLabel(k : Key, p : Prefix, s : LabeledTree) : ?T {
    mkPrefix(k, p, s, null);
  };

  func mkPrefix(k : Key, p : Prefix, s : LabeledTree, rest : ?T) : ?T {
    // Enforce invariant that labels do not contain empty trees
    switch (s) { case (#subtree(null)) { return rest; }; case (_) {}; };
      
    let labeled_hash = hashLabeled(k, labeledTreeHash(s));

    let tree_hash = switch (rest) {
      case null { labeled_hash };
      case (?rest) { hashFork(labeled_hash, hashT(rest)); };
    };

    ? (#prefix {
      key = k;
      prefix = p;
      labeled_hash = labeled_hash;
      here = s;
      rest = rest;
      tree_hash = tree_hash;
    })
  };

  func mkFork(i : Dyadic.Interval, t1 : ?T, t2 : ?T) : ?T {
    switch t1 {
      case null { t2 };
      case (?t1) {
        switch t2 {
          case null { ? t1 };
          case (?t2) {
            ? (#fork {
              interval = i;
              hash = hashFork(hashT(t1), hashT(t2));
              left = t1;
              right = t2;
            })
          }
        }
      }
    }
  };

  // Insertion

  func putIter(t : LabeledTree, ki : Iter.Iter<Key>, v : Value) : LabeledTree {
    switch (ki.next()) {
      case (null) { #leaf(mkLeaf(v)) };
      case (?k) { 
        modifyLabeledTree(t, k, func (s) { putIter(s, ki, v) })
      };
    }
  };

  func deleteIter(t : LabeledTree, ki : Iter.Iter<Key>) : LabeledTree {
    switch (ki.next()) {
      case (null) { #subtree(null) };
      case (?k) { 
        modifyLabeledTree(t, k, func (s) { deleteIter(s, ki) })
      };
    }
  };

  // Modification (in particular insertion)

  func modifyLabeledTree(t : LabeledTree, k : Key, f : LabeledTree -> LabeledTree) : LabeledTree {
    // If we are supposed to modify at a label, but encounter a leaf, we throw it away and 
    // pretend its an empty tree
    let ot = switch (t) {
      case (#leaf _) { null };
      case (#subtree s) { s };
    };
    #subtree (modifyOT(ot, k, Blob.toArray(k), f))
  };

  func modifyOT(t : OT, k : Key, p : Prefix, f : LabeledTree -> LabeledTree) : ?T {
    switch t {
      case null { mkLabel(k, p, f (#subtree null)) };
      case (?t) { modifyT(t, k, p, f) };
    }
  };

  func modifyT(t : T, k : Key, p : Prefix, f : LabeledTree -> LabeledTree) : ?T {
    switch (Dyadic.find(p, intervalT(t))) {
      case (#before(i)) {
        mkFork(Dyadic.mk(p, i), mkLabel(k, p, f (#subtree null)), ? t)
      };
      case (#after(i)) {
        mkFork(Dyadic.mk(p, i), ? t, mkLabel(k, p, f (#subtree null)))
      };
      case (#needle_is_prefix) {
        mkPrefix(k,p,f (#subtree null), ?t)
      };
      case (#equal) {
        modifyHere(t, k, p, f)
      };
      case (#in_left_half) {
        modifyLeft(t, k, p, f);
      };
      case (#in_right_half) {
        modifyRight(t, k, p, f);
      };
    }
  };

  func modifyHere(t : T, k : Key, p : Prefix, f : LabeledTree -> LabeledTree) : ?T {
    switch (t) {
      case (#prefix(l)) {
        mkPrefix(k, p, f (l.here), l.rest) 
      };
      case (#fork(_)) {
        mkPrefix(k, p, f (#subtree null), ?t);
      };
    }
  };

  func modifyLeft(t : T, k : Key, p : Prefix, f : LabeledTree -> LabeledTree) : ?T {
    switch (t) {
      case (#fork(frk)) {
        mkFork(frk.interval, modifyT(frk.left, k, p, f), ? frk.right)
      };
      case (#prefix(l)) {
        mkPrefix(l.key, l.prefix, l.here, modifyOT(l.rest, k, p, f))
      }
    }
  };

  func modifyRight(t : T, k : Key, p : Prefix, f : LabeledTree -> LabeledTree) : ?T {
    switch (t) {
      case (#fork(frk)) {
        mkFork(frk.interval, ?frk.left, modifyT(frk.right, k, p, f))
      };
      case (#prefix(l)) {
        mkPrefix(l.key, l.prefix, l.here, modifyOT(l.rest, k, p, f))
      }
    }
  };

  // Querying

  func lookupIter(t : LabeledTree, ki : Iter.Iter<Key>) : LabeledTree {
    switch (ki.next()) {
      case (null) { t };
      case (?k) { lookupIter(lookupLabel(t, Blob.toArray(k)), ki) };
    }
  };
  
  func lookupLabel(t : LabeledTree, p : Prefix) : LabeledTree {
    switch (t) {
      case (#leaf _) { #subtree(null) };
      case (#subtree(t)) { lookupOT(t, p) };
    };
  };

  func lookupOT(t : OT, p : Prefix) : LabeledTree {
    switch (t) {
      case null { #subtree(null) };
      case (?t) { lookupT(t, p) };
    };
  };

  func lookupT(t : T, p : Prefix) : LabeledTree {
    switch (Dyadic.find(p, intervalT(t))) {
      case (#before(i)) { #subtree(null) };
      case (#after(i)) { #subtree(null) };
      case (#needle_is_prefix) { #subtree(null) };
      case (#equal) { 
        switch (t) {
          case (#fork(f)) { #subtree(null); };
          case (#prefix(n)) { n.here }; // Found it!
        };
      };
      case (#in_left_half) {
        switch (t) {
          case (#fork(f)) { lookupT(f.left, p); };
          case (#prefix(n)) { lookupOT(n.rest, p); };
        };
      };
      case (#in_right_half) {
        switch (t) {
          case (#fork(f)) { lookupT(f.right, p); };
          case (#prefix(n)) { lookupOT(n.rest, p); };
        };
      };
    }
  };

  func iterLabels(t : T) : Iter.Iter<Key> {
    let stack = Stack.Stack<T>();
    stack.push(t);
    { next = func () : ?Key {
      loop {
        switch(stack.pop()){
          case (null) { return null };
          case (?#fork(f)) {
            stack.push(f.right);
            stack.push(f.left);
          };
          case (?#prefix(f)) {
            switch (f.rest) {
              case (null) {};
              case (?t) { stack.push(t) };
            };
            return (? f.key);
          }
        }
      }
    }}
  };
  
  
  // Witness construction

  /// Create a witness that reveals the value of the key `k` in the tree `tree`.
  ///
  /// If `k` is not in the tree, the witness will prove that fact.
  public func reveal(tree : Tree, path : Path) : Witness {
    revealIter(tree, path.vals())
  };

  func revealIter(tree : LabeledTree, ki : Iter.Iter<Key>) : Witness {
    switch (ki.next()) {
      case (null) { 
        switch (tree) {
          case (#leaf(l)) { #leaf(l.value) };
          // What to reveal when the location is not a value but a subtree?
          // If empty, reveal that
          case (#subtree(null)) { #empty };
          // else reveal its root hash
          case (#subtree(?t)) { #pruned(hashT(t)) };
        }
      };
      case (?k) { 
        switch (tree) {
          // What to reveal when a value is on the way the path?
          // Let's reveal it in purned form
          case (#leaf(l)) { #pruned(treeHash(tree)) };
          case (#subtree(s)) { 
            switch (s) {
              case null { #empty };
              case (?t) {
                let (_, w, _) = revealT(t, Blob.toArray(k), ki);
                w
              }
            }
          }
        }
      };
    }
  };

  // Returned bools indicate whether to also reveal left or right neighbor
  func revealT(t : T, p : Prefix, ki : Iter.Iter<Key>) : (Bool, Witness, Bool) {
    switch (Dyadic.find(p, intervalT(t))) {
      case (#before(i)) {
        (true, revealMinKey(t), false);
      };
      case (#after(i)) {
        (false, revealMaxKey(t), true);
      };
      case (#equal) {
        revealLeaf(t, ki);
      };
      case (#needle_is_prefix) {
        (true, revealMinKey(t), false);
      };
      case (#in_left_half) {
        revealLeft(t, p, ki);
      };
      case (#in_right_half) {
        revealRight(t, p, ki);
      };
    }
  };

  func revealMinKey(t : T) : Witness {
    switch (t) {
      case (#fork(f)) {
        #fork(revealMinKey(f.left), #pruned(hashT(f.right)))
      };
      case (#prefix(l)) {
        #labeled(l.key, #pruned(labeledTreeHash(l.here)));
      }
    }
  };

  func revealMaxKey(t : T) : Witness {
    switch (t) {
      case (#fork(f)) {
        #fork(#pruned(hashT(f.left)), revealMaxKey(f.right))
      };
      case (#prefix(l)) {
        switch (l.rest) {
          case null { #labeled(l.key, #pruned(labeledTreeHash(l.here))) };
          case (?t) { #fork(#pruned(l.labeled_hash), revealMaxKey(t)) };
        }
      }
    }
  };

  func revealLeaf(t : T, ki : Iter.Iter<Key>) : (Bool, Witness, Bool) {
    switch (t) {
      case (#fork(f)) { (true, revealMinKey(t), false); };
      case (#prefix(l)) {
        let lw = #labeled(l.key, revealIter(l.here, ki));
        switch (l.rest) {
          case (null) { (false, lw, false) };
          case (?t)   { (false, #fork(lw, #pruned(hashT(t))), false); }
        }
      }
    }
  };

  func revealLeft(t : T, p : Prefix, ki : Iter.Iter<Key>) : (Bool, Witness, Bool) {
    switch (t) {
      case (#fork(f)) {
        let (b1,w1,b2) = revealT(f.left, p, ki);
        let w2 = if b2 { revealMinKey(f.right) } else { #pruned(hashT(f.right)) };
        (b1, #fork(w1, w2), false);
      };
      case (#prefix(l)) {
        switch (l.rest) {
          case null { (false, #labeled(l.key, #pruned(labeledTreeHash(l.here))), true); };
          case (?t2) {
            let (b1,w1,b2) = revealT(t2, p, ki);
            let w0 = if b1 { #labeled(l.key, #pruned(labeledTreeHash(l.here))) }
                     else { #pruned(l.labeled_hash) };
            (false, #fork(w0, w1), b2);
          }
        }
      }
    }
  };

  func revealRight(t : T, p : Prefix, ki : Iter.Iter<Key>) : (Bool, Witness, Bool) {
    switch (t) {
      case (#fork(f)) {
        let (b1,w2,b2) = revealT(f.right, p, ki);
        let w1 = if b1 { revealMaxKey(f.left) } else { #pruned(hashT(f.left)) };
        (false, #fork(w1, w2), b2);
      };
      case (#prefix(l)) {
        switch (l.rest) {
          case null { (false, #labeled(l.key, #pruned(labeledTreeHash(l.here))), true); };
          case (?t2) {
            let (b1,w1,b2) = revealT(t2, p, ki);
            let w0 = if b1 { #labeled(l.key, #pruned(labeledTreeHash(l.here))) }
                     else { #pruned(l.labeled_hash) };
            (false, #fork(w0, w1), b2);
          }
        }
      }
    }
  };

  /// Merges two witnesses, to reveal multiple values.
  ///
  /// The two witnesses must come from the same tree, else this function is
  /// undefined (and may trap).
  public func merge(w1 : Witness, w2 : Witness) : Witness {
    switch (w1, w2) {
      case (#pruned(h1), #pruned(h2)) {
        if (h1 != h2) Debug.print("MerkleTree.merge: pruned hashes differ");
        #pruned(h1)
      };
      case (#pruned _, w2) w2;
      case (w1, #pruned _) w1;
      // If both witnesses are not pruned, they must be headed by the same
      // constructor:
      case (#empty, #empty) #empty;
      case (#labeled(l1, w1), #labeled(l2, w2)) {
        if (l1 != l2) Debug.print("MerkleTree.merge: labels differ");
        #labeled(l1, merge(w1, w2));
      };
      case (#fork(w11, w12), #fork(w21, w22)) {
        #fork(merge(w11, w21), merge(w12, w22))
      };
      case (#leaf(v1), #leaf(v2)) {
        if (v1 != v2) Debug.print("MerkleTree.merge: values differ");
        #leaf(v2)
      };
      case (_,_) {
        Debug.print("MerkleTree.merge: shapes differ");
        #empty;
      }
    }
  };

  /// Reveal nothing from the tree. Mostly useful as a netural element to `merge`.
  public func revealNothing(tree : Tree) : Witness {
    #pruned(treeHash(tree))
  };

  /// Reveals multiple paths
  public func reveals(tree : Tree, ks : Iter.Iter<Path>) : Witness {
    // Odd, no Iter.fold? Then let’s do a mutable loop
    var w = revealNothing(tree);
    for (k in ks) { w := merge(w, reveal(tree, k)); };
    return w;
  };

  /// We can reconstruct the root witness from a witness
  public func reconstruct(w: Witness) : Hash {
    switch(w){
      case(#pruned(prunedHash)){ prunedHash };
      case(#empty){ hashEmpty() };
      case(#leaf(v)){ hashLeaf(v) };
      case(#labeled(k,w)){ hashLabeled(k, reconstruct w); };
      case(#fork(l,r)){ hashFork(reconstruct(l), reconstruct(r)) };
    };
  };

  /// The return type of `structure`
  public type RawTree = {
    #value : Blob;
    #subtree : [(Key, RawTree)];
  };

  /// Extract the raw data from the trees, mostly for pretty-printing
  public func structure(t : Tree) : RawTree {
    switch (t) {
      case (#leaf(v)) { #value(v.value) };
      case (#subtree(t)) {
        let b = Buffer.Buffer<(Key,RawTree)>(10);
        collectOT(t, b);
        #subtree(Buffer.toArray(b));
      };
    };
  };

  func collectOT(t : OT, b : Buffer.Buffer<(Key, RawTree)>) {
    switch(t) {
      case null {};
      case (?t) (collectT(t,b));
    };
  };

  func collectT(t : T, b : Buffer.Buffer<(Key, RawTree)>) {
    switch(t) {
      case (#prefix(p))  { 
          b.add((p.key, structure(p.here)));
          collectOT(p.rest, b);
      };
      case (#fork(f)) {
          collectT(f.left, b);
          collectT(f.right, b);
       };
    };
  };

  /// The CBOR encoding of a Witness, according to
  /// <https://sdk.dfinity.org/docs/interface-spec/index.html#certification-encoding>
  /// including the CBOR self-describing tag
  public func encodeWitness(tree : Witness) : Blob {

    // This data structure needs only very few features of CBOR, so instead of writing
    // a full-fledged CBOR encoding library, I just directly write out the bytes for the
    // few constructs we need here.

    func add_blob(buf : Buffer.Buffer<Nat8>, b: Blob) {
      // Header
      let len = b.size();
      if (len <= 23) {
        buf.add(2 << 5 + Nat8.fromNat(len));
      } else if (len <= 0xff) {
        buf.add(0x58);
        buf.add(Nat8.fromNat(len));
      } else if (len <= 0xffff) {
        buf.add(0x59);
        buf.add(Nat8.fromIntWrap(len / 0x100));
        buf.add(Nat8.fromIntWrap(len));
      } else if (len <= 0xffffff) {
        buf.add(0x5a);
        buf.add(Nat8.fromIntWrap(len / 0x10000));
        buf.add(Nat8.fromIntWrap(len / 0x100));
        buf.add(Nat8.fromIntWrap(len));
      } else if (len <= 0xffffffff) {
        buf.add(0x5b);
        buf.add(Nat8.fromIntWrap(len / 0x1000000));
        buf.add(Nat8.fromIntWrap(len / 0x10000));
        buf.add(Nat8.fromIntWrap(len / 0x100));
        buf.add(Nat8.fromIntWrap(len));
      } else {
        Debug.trap("Blob too long to serialize");
      };

      for (c in Blob.toArray(b).vals()) {
        buf.add(c);
      };
    };

    func go(buf : Buffer.Buffer<Nat8>, t : Witness) {
      switch (t) {
        case (#empty)        { buf.add(0x81); buf.add(0x00); };
        case (#fork(t1,t2))  { buf.add(0x83); buf.add(0x01); go(buf, t1); go (buf, t2); };
        case (#labeled(l,t)) { buf.add(0x83); buf.add(0x02); add_blob(buf, l); go (buf, t); };
        case (#leaf(v))      { buf.add(0x82); buf.add(0x03); add_blob(buf, v); };
        case (#pruned(h))    { buf.add(0x82); buf.add(0x04); add_blob(buf, h); }
      }
    };

    let buf = Buffer.Buffer<Nat8>(100);

    // CBOR self-describing tag
    buf.add(0xD9);
    buf.add(0xD9);
    buf.add(0xF7);

    go(buf, tree);

    return Blob.fromArray(Buffer.toArray(buf));
  };


}

