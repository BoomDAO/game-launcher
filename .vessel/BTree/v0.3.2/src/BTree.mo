/// The BTree module collection of functions and types

import Types "./Types";
import AU "./ArrayUtil";
import BS "./BinarySearch";
import NU "./NodeUtil";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import O "mo:base/Order";
import Nat "mo:base/Nat";
import Stack "mo:base/Stack";

module {
  public type BTree<K, V> = Types.BTree<K, V>;
  public type Node<K, V> = Types.Node<K, V>;
  public type Internal<K, V> = Types.Internal<K, V>;
  public type Leaf<K, V> = Types.Leaf<K, V>;
  public type Data<K, V> = Types.Data<K, V>;

  /// Initializes an empty BTree. By default, set the BTree to have order 8, and enforce the the order be greater than 4, but lower than 512
  public func init<K, V>(order: ?Nat): BTree<K, V> {
    let btreeOrder = switch(order) {
      case null { 32 };
      case (?providedOrder) { 
        if (providedOrder < 4) { Debug.trap("provided order=" # Nat.toText(providedOrder) # ", but Btree order must be >= 4 and <= 512") };
        if (providedOrder > 512) { Debug.trap("provided order=" # Nat.toText(providedOrder) # ", but Btree order must be >= 4 and <= 512") };
        providedOrder
      };
    };

    {
      var root = #leaf({
        data = {
          kvs = Array.tabulateVar<?(K, V)>(btreeOrder - 1, func(i) { null });
          var count = 0;
        };
      }); 
      var size = 0;
      order = btreeOrder;
    }
  };
  
  /// Allows one to quickly create a BTree from an array of key value pairs
  public func fromArray<K, V>(order: Nat, compare: (K, K) -> O.Order, kvPairs: [(K, V)]): BTree<K, V> {
    let t = init<K, V>(?order);
    let _ = Array.map<(K, V), ?V>(kvPairs, func(pair) {
      insert<K, V>(t, compare, pair.0, pair.1);
    });

    t
  };

  /// Allows one to quickly create a BTree from an Buffer of key value pairs
  ///
  /// The Buffer class type returned is described in the Motoko-base library here:
  /// https://github.com/dfinity/motoko-base/blob/master/src/Buffer.mo
  /// It does **not** persist to stable memory
  public func fromBuffer<K, V>(order: Nat, compare: (K, K) -> O.Order, kvPairs: Buffer.Buffer<(K, V)>): BTree<K, V> {
    let t = init<K, V>(?order);
    for ((k, v) in kvPairs.vals()) {
      ignore insert<K, V>(t, compare, k, v);
    };

    t
  };

  /// Get the current count of key-value pairs present in the BTree
  public func size<K, V>(tree: BTree<K, V>): Nat { tree.size };

  /// Retrieves the value corresponding to the key of BTree if it exists
  public func get<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K): ?V {
    switch(tree.root) {
      case (#internal(internalNode)) { getFromInternal(internalNode, compare, key) };
      case (#leaf(leafNode)) { getFromLeaf(leafNode, compare, key) }
    }
  };

  /// Returns a boolean representing if the BTree contains the provided key or not
  public func has<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K): Bool {
    switch(get<K, V>(tree, compare, key)) {
      case null { false };
      case (?v) { true };
    }
  };

  /// Inserts an element into a BTree
  public func insert<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K, value: V): ?V {
    let insertResult = switch(tree.root) {
      case (#leaf(leafNode)) { leafInsertHelper<K, V>(leafNode, tree.order, compare, key, value) };
      case (#internal(internalNode)) { internalInsertHelper<K, V>(internalNode, tree.order, compare, key, value) };
    };

    switch(insertResult) {
      case (#insert(ov)) {
        switch(ov) {
          // if inserted a value that was not previously there, increment the tree size counter
          case null { tree.size += 1 };
          case _ {};
        };
        ov
      };
      case (#promote({ kv; leftChild; rightChild; })) {
        tree.root := #internal({
          data = {
            kvs = Array.tabulateVar<?(K, V)>(tree.order - 1, func(i) {
              if (i == 0) { ?kv }
              else { null }
            });
            var count = 1;
          };
          children = Array.tabulateVar<?(Node<K, V>)>(tree.order, func(i) {
            if (i == 0) { ?leftChild }
            else if (i == 1) { ?rightChild }
            else { null }
          });
        });
        // promotion always comes from inserting a new element, so increment the tree size counter
        tree.size += 1;

        null
      }
    };
  };

  /// Substitutes in a new key in for the current/old key, preserving the same attributes as the previous key (if the key previously exists in the BTree).
  /// This returns the value associated with the old key if it exists, otherwise it returns null
  ///
  /// Note: Under the hood, this is implemented as two operations:
  /// 1) delete the old key
  /// 2) insert the new key with the same value as the previously deleted old key
  public func substituteKey<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, oldKey: K, newKey: K): ?V {
    switch(delete<K, V>(tree, compare, oldKey)) {
      case null { null };
      case (?v) {
        ignore insert<K, V>(tree, compare, newKey, v);
        ?v
      }
    }
  };

  /// Applies a function to the value of an existing key of a BTree
  /// If the element does not yet exist in the BTree it creates a new key and value according to the result of passing null to the updateFunction
  public func update<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K, updateFunction: (?V) -> V): ?V {
    let updateResult = switch(tree.root) {
      case (#leaf(leafNode)) { leafUpdateHelper<K, V>(leafNode, tree.order, compare, key, updateFunction) };
      case (#internal(internalNode)) { internalUpdateHelper<K, V>(internalNode, tree.order, compare, key, updateFunction) };
    };

    switch(updateResult) {
      case (#insert(ov)) { 
        switch(ov) {
          case null { tree.size := tree.size + 1 };
          case _ {};
        };
        ov
      };
      case (#promote({ kv; leftChild; rightChild; })) {
        tree.root := #internal({
          data = {
            kvs = Array.tabulateVar<?(K, V)>(tree.order - 1, func(i) {
              if (i == 0) { ?kv }
              else { null }
            });
            var count = 1;
          };
          children = Array.tabulateVar<?(Node<K, V>)>(tree.order, func(i) {
            if (i == 0) { ?leftChild }
            else if (i == 1) { ?rightChild }
            else { null }
          });
        });
        // promotion always comes from inserting a new element, so increment the tree size counter
        tree.size += 1;

        null
      }
    };
  };

  /// Deletes an element from a BTree
  public func delete<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K): ?V {
    switch(tree.root) {
      case (#leaf(leafNode)) {
        // TODO: think about how this can be optimized so don't have to do two steps (search and then insert)?
        switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
          case (#keyFound(deleteIndex)) { 
            leafNode.data.count -= 1;
            let (_, deletedValue) = AU.deleteAndShiftValuesOver<(K, V)>(leafNode.data.kvs, deleteIndex);
            tree.size -= 1;
            ?deletedValue
          };
          case _ { null }
        }
      };
      case (#internal(internalNode)) { 
        let deletedValueResult = switch(internalDeleteHelper(internalNode, tree.order, compare, key, false)) {
          case (#delete(value)) { value };
          case (#mergeChild({ internalChild; deletedValue })) {
            if (internalChild.data.count > 0) {
              tree.root := #internal(internalChild);
            }
            // This case will be hit if the BTree has order == 4
            // In this case, the internalChild has no keys (last key was merged with new child), so need to promote that merged child (its only child)
            else {
              tree.root := switch(internalChild.children[0]) {
                case (?node) { node };
                case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.delete(), element deletion failed, due to a null replacement node error") };
              };
            };
            deletedValue
          }
        };

        switch(deletedValueResult) {
          // if deleted a value from the BTree, decrement the size
          case (?deletedValue) { tree.size -= 1 };
          case null {}
        };
        deletedValueResult
      }
    }
  };

  /// Returns the minimum key in a BTree with its associated value. If the BTree is empty, returns null
  public func min<K, V>(tree: BTree<K, V>): ?(K, V) {
    switch(tree.root) {
      case (#leaf(leafNode)) { getLeafMin<K, V>(leafNode) };
      case (#internal(internalNode)) { getInternalMin<K, V>(internalNode) };
    }
  };

  /// Returns the maximum key in a BTree with its associated value. If the BTree is empty, returns null
  public func max<K, V>(tree: BTree<K, V>): ?(K, V) {
    switch(tree.root) {
      case (#leaf(leafNode)) { getLeafMax<K, V>(leafNode) };
      case (#internal(internalNode)) { getInternalMax<K, V>(internalNode) };
    }
  };

  /// Deletes the minimum key in a BTree and returns its associated value. If the BTree is empty, returns null
  public func deleteMin<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order): ?(K, V) {
    switch(min(tree)) {
      case (?(k, v)) {
        ignore delete<K, V>(tree, compare, k);
        ?(k, v);
      };
      case null { null }
    }
  };

  /// Deletes the maximum key in a BTree and returns its associated value. If the BTree is empty, returns null
  public func deleteMax<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order): ?(K, V) {
    switch(max(tree)) {
      case (?(k, v)) {
        ignore delete<K, V>(tree, compare, k);
        ?(k, v);
      };
      case null { null }
    }
  };

  /// Returns an ascending order BTree iterator
  public func entries<K, V>(t: BTree<K, V>): Iter.Iter<(K, V)> {
    switch(t.root) {
      case (#leaf(leafNode)) { return leafEntries(leafNode) };
      case (#internal(internalNode)) { internalEntries(internalNode) };
    };
  };

  /// Returns an array of all the key-value pairs in the BTree
  ///
  /// Note: If the BTree contains more entries than the message instruction limit will allow you to process in across consensus this may trap mid-iteration
  public func toArray<K, V>(t: BTree<K, V>): [(K, V)] {
    Buffer.toArray<(K, V)>(toBuffer<K, V>(t));
  };

  /// Returns a buffer of all the key-value pairs in the BTree.
  ///
  /// The Buffer class type returned is described in the Motoko-base library here:
  /// https://github.com/dfinity/motoko-base/blob/master/src/Buffer.mo
  /// It does **not** persist to stable memory
  ///
  /// Note: If the BTree contains more entries than the message instruction limit will allow you to process in across consensus this may trap mid-iteration
  public func toBuffer<K, V>(t: BTree<K, V>): Buffer.Buffer<(K, V)> {
    // initialize the accumulator buffer to have the same size as the BTree (to avoid resizing)
    let entriesAccumulator = Buffer.Buffer<(K, V)>(t.size);
    switch(t.root) {
      case (#leaf(leafNode)) { appendLeafKVs(leafNode, entriesAccumulator) };
      case (#internal(internalNode)) { appendInternalKVs(internalNode, entriesAccumulator) };
    };
    entriesAccumulator;
  };


  /// The direction of iteration
  /// \#fwd -> forward (ascending)
  /// \#bwd -> backwards (descending)
  public type Direction = { #fwd; #bwd };

  /// The object returned from a scan contains:
  /// * results - a key value array of all results found (within the bounds and limit provided)
  /// * nextKey - an optional next key if there exist more results than the limit provided within the given bounds
  public type ScanLimitResult<K, V> = {
    results: [(K, V)];
    nextKey: ?K;
  };

  /// Performs a in-order scan of the Red-Black Tree between the provided key bounds, returning a number of matching entries in the direction specified (ascending/descending) limited by the limit parameter specified in an array formatted as (K, V) for each entry
  ///
  /// * tree - the BTree being scanned
  /// * compare - the comparison function used to compare (in terms of order) the provided bounds against the keys in the BTree
  /// * lowerBound - the lower bound used in the scan
  /// * upperBound - the upper bound used in the scan
  /// * dir - the direction of the scan
  /// * limit - the maximum possible number of items to scan (that are between the lower and upper bounds) before returning
  public func scanLimit<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, dir: Direction, limit: Nat): ScanLimitResult<K, V> {
    if (limit == 0) { return { results = []; nextKey = null }};

    switch(compare(lowerBound, upperBound)) {
      // return empty array if lower bound is greater than upper bound      
      case (#greater) {{ results = []; nextKey = null }};
      // return the single entry if exists if the lower and upper bounds are equivalent
      case (#equal) { 
        switch(get<K, V>(tree, compare, lowerBound)) {
          case null {{ results = []; nextKey = null }};
          case (?value) {{ results = [(lowerBound, value)]; nextKey = null }};
        }
      };
      case (#less) { 
        // add 1 to limit to allow additional space for next key without worrying about Nat underflow
        let limitPlusNextKey = limit + 1;
        let { resultBuffer; nextKey } = iterScanLimit<K, V>(tree.root, compare, lowerBound, upperBound, dir, limitPlusNextKey);
        { results = Buffer.toArray(resultBuffer); nextKey = nextKey };
      }
    }
  };


  ///////////////////////////////////////
  /* Internal Library Helper functions*/
  /////////////////////////////////////

  // gets the max key value pair in the leaf node
  func getLeafMin<K, V>({ data }: Leaf<K, V>): ?(K, V) {
    if (data.count == 0) null else { data.kvs[0] }
  };

  // gets the min key value pair in the internal node
  func getInternalMin<K, V>(internal: Internal<K, V>): ?(K, V) {
    var currentInternal = internal;
    var minKV: ?(K, V) = null;
    label l loop {
      let child = switch(currentInternal.children[0]) {
        case (?child) { child };
        case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.internalmin(), null child error") };
      };

      switch(child) {
        case (#leaf(leafNode)) {
          minKV := getLeafMin<K, V>(leafNode);
          break l
        };
        case (#internal(internalNode)) { currentInternal := internalNode; };
      }
    };
    minKV;
  };

  // gets the max key value pair in the leaf node
  func getLeafMax<K, V>({ data }: Leaf<K, V>): ?(K, V) {
    if (data.count == 0) null else { data.kvs[data.count - 1] }
  };

  // gets the max key value pair in the internal node
  func getInternalMax<K, V>(internal: Internal<K, V>): ?(K, V) {
    var currentInternal = internal;
    var maxKV: ?(K, V) = null;
    label l loop {
      let child = switch(currentInternal.children[currentInternal.data.count]) {
        case (?child) { child };
        case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.internalGetMax(), null child error") };
      };

      switch(child) {
        case (#leaf(leafNode)) {
          maxKV := getLeafMax<K, V>(leafNode);
          break l
        };
        case (#internal(internalNode)) { currentInternal := internalNode; };
      }
    };
    maxKV;
  };

  // Appends all kvs in the leaf to the entriesAccumulator buffer 
  func appendLeafKVs<K, V>({ data }: Leaf<K, V>, entriesAccumulator: Buffer.Buffer<(K, V)>): () {
    var i = 0;
    while (i < data.count) {
      switch(data.kvs[i]) {
        case (?kv) { entriesAccumulator.add(kv) };
        case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In appendLeafEntries data.kvs[i] is null with data.count=" # Nat.toText(data.count) # " and i=" # Nat.toText(i)) };
      };
      i += 1;
    };
  };

  // Iterates through the entire internal node, appending all kvs to the entriesAccumulator buffer
  func appendInternalKVs<K, V>(internal: Internal<K, V>, entriesAccumulator: Buffer.Buffer<(K, V)>): () {
    // Holds an internal node stack cursor for iterating through the BTree
    let internalNodeStack = initializeInternalNodeStack(internal, entriesAccumulator);
    var internalCursor = internalNodeStack.pop();

    label l loop {
      switch(internalCursor) {
        case (?{ internal; kvIndex }) {
          switch(internal.data.kvs[kvIndex]) {
            case (?kv) { entriesAccumulator.add(kv) };
            case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalEntries internal.data.kvs[kvIndex] is null with internal.data.count=" # Nat.toText(internal.data.count) # " and kvIndex=" # Nat.toText(kvIndex)) };
          };
          let lastKV = (internal.data.count - 1: Nat);
          if (kvIndex > lastKV) {
            Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalEntries kvIndex=" # Nat.toText(kvIndex) # " is greater than internal.data.count=" # Nat.toText(internal.data.count))
          };

          // push the new internalCursor onto the stack, and traverse the left child of the internal node
          // increment the kvIndex of the internalCursor,
          let nextCursor = { internal = internal; kvIndex = kvIndex + 1 };
          // if the kvIndex is less than the number of keys in the internal node, push the new internalCursor onto the stack,
          if (kvIndex < lastKV) {
            internalNodeStack.push(nextCursor);
          };

          // traverse the next child's min subtree and push the resulting internal cursors to the stack
          traverseInternalMinSubtree(internalNodeStack, nextCursor, entriesAccumulator);
          // pop the next internalCursor off the stack and continue
          internalCursor := internalNodeStack.pop();
        };
        // nothing left in the internalNodeStack, signalling that we have traversed the entire BTree and added all kv pairs to the entriesAccumulator
        case null { return };
      };
    }
  };

  func initializeInternalNodeStack<K, V>(internal: Internal<K, V>, entriesAccumulator: Buffer.Buffer<(K, V)>): Stack.Stack<InternalCursor<K, V>> {
    let internalNodeStack = Stack.Stack<InternalCursor<K, V>>();
    let internalCursor: InternalCursor<K, V> = {
      internal;
      kvIndex = 0;
    };
    internalNodeStack.push(internalCursor);
    traverseInternalMinSubtree(internalNodeStack, internalCursor, entriesAccumulator);

    internalNodeStack;
  };

  // traverse the min subtree of the current internal cursor, passing each new element to the node cursor stack
  // once a leaf node is hit, appends all the leaf entries to the entriesAccumulator buffer and returns
  func traverseInternalMinSubtree<K, V>(internalNodeStack: Stack.Stack<InternalCursor<K, V>>, internalCursor: InternalCursor<K, V>, entriesAccumulator: Buffer.Buffer<(K, V)>): () {
    var currentNode = internalCursor.internal;
    var childIndex = internalCursor.kvIndex;
    label l loop {
      switch(currentNode.children[childIndex]) {
        // If hit a leaf, have hit the bottom of the min subtree, so can just append all leaf entries to the accumulator and return (no need to push to the stack)
        case (?#leaf(leafChild)) {
          appendLeafKVs(leafChild, entriesAccumulator);
          return;
        };
        // If hit an internal node, update the currentNode and childIndex, and push the min child index of that internal node onto the stack
        case (?#internal(internalNode)) {
          currentNode := internalNode;
          childIndex := 0;
          internalNodeStack.push({
            internal = internalNode;
            kvIndex = childIndex;
          });
        };
        case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In dfsTraverse, currentNode.children[childIndex] is null with currentNode.data.count=" # Nat.toText(currentNode.data.count) # " and childIndex=" # Nat.toText(childIndex)) };
      };
    };
  };

  func leafEntries<K, V>({ data }: Leaf<K, V>): Iter.Iter<(K, V)> {
    var i: Nat = 0;
    object {
      public func next() : ?(K, V) {
        if (i >= data.count) {
          return null
        } else {
          let res = data.kvs[i];
          i += 1;
          return res
        }
      }
    }
  };

  // Cursor type that keeps track of the current node and the current key-value index in the node 
  type NodeCursor<K, V> = { node: Node<K, V>; kvIndex: Nat };

  func internalEntries<K, V>(internal: Internal<K, V>): Iter.Iter<(K, V)> {
    object {
      // The nodeCursorStack keeps track of the current node and the current key-value index in the node
      // We use a stack here to push to/pop off the next node cursor to visit
      let nodeCursorStack = initializeNodeCursorStack(internal);

      public func next(): ?(K, V) {
        // pop the next node cursor off the stack
        var nodeCursor = nodeCursorStack.pop();
        switch(nodeCursor) {
          case null { return null };
          case (?{ node; kvIndex }) {
            switch(node) {
              // if a leaf node, iterate through the leaf node's next key-value pair
              case (#leaf(leafNode)) {
                let lastKV = leafNode.data.count - 1: Nat;
                if (kvIndex > lastKV) {
                  Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.internalEntries(), leaf kvIndex out of bounds");
                };

                let currentKV = switch(leafNode.data.kvs[kvIndex]) {
                  case (?kv) { kv };
                  case null { Debug.trap(
                    "UNREACHABLE_ERROR: file a bug report! In BTree.internalEntries(), null key-value pair found in leaf node."
                    # "leafNode.data.count=" # Nat.toText(leafNode.data.count) # ", kvIndex=" # Nat.toText(kvIndex)
                  ) };
                };
                // if not at the last key-value pair, push the next key-value index of the leaf onto the stack and return the current key-value pair
                if (kvIndex < lastKV) {
                  nodeCursorStack.push({ node = #leaf(leafNode); kvIndex = kvIndex + 1 });
                };

                // return the current key-value pair
                ?currentKV;
              };
              // if an internal node
              case (#internal(internalNode)) {
                let lastKV = internalNode.data.count - 1: Nat;
                // Developer facing message in case of a bug
                if (kvIndex > lastKV) {
                  Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.internalEntries(), internal kvIndex out of bounds");
                };

                let currentKV = switch(internalNode.data.kvs[kvIndex]) {
                  case (?kv) { kv };
                  case null { Debug.trap(
                    "UNREACHABLE_ERROR: file a bug report! In BTree.internalEntries(), null key-value pair found in internal node. " #
                    "internal.data.count=" # Nat.toText(internalNode.data.count) # ", kvIndex=" # Nat.toText(kvIndex)
                  ) };
                };

                let nextCursor = { node = #internal(internalNode); kvIndex = kvIndex + 1 };
                // if not the last key-value pair, push the next key-value index of the internal node onto the stack
                if (kvIndex < lastKV) {
                  nodeCursorStack.push(nextCursor);
                };
                // traverse the next child's min subtree and push the resulting node cursors onto the stack
                // then return the current key-value pair of the internal node
                traverseMinSubtreeIter(nodeCursorStack, nextCursor);
                ?currentKV
              }
            }
          }
        }
      }
    }
  };

  func initializeNodeCursorStack<K, V>(internal: Internal<K, V>): Stack.Stack<NodeCursor<K, V>> {
    let nodeCursorStack = Stack.Stack<NodeCursor<K, V>>();
    let nodeCursor: NodeCursor<K, V> = {
      node = #internal(internal);
      kvIndex = 0;
    };

    // push the initial cursor to the stack
    nodeCursorStack.push(nodeCursor);
    // then traverse left
    traverseMinSubtreeIter(nodeCursorStack, nodeCursor);
    nodeCursorStack;
  };


  // traverse the min subtree of the current node cursor, passing each new element to the node cursor stack
  func traverseMinSubtreeIter<K, V>(nodeCursorStack: Stack.Stack<NodeCursor<K, V>>, nodeCursor: NodeCursor<K, V>): () {
    var currentNode = nodeCursor.node;
    var childIndex = nodeCursor.kvIndex;

    label l loop {
      switch(currentNode) {
        // If currentNode is leaf, have hit the minimum element of the subtree and already pushed it's cursor to the stack
        // so can return
        case (#leaf(leafNode)) {
          return;
        };
        // If currentNode is internal, add it's left most child to the stack and continue traversing
        case (#internal(internalNode)) {
          switch(internalNode.children[childIndex]) {
            // Push the next min (left most) child node to the stack
            case (?childNode) {
              childIndex := 0;
              currentNode := childNode;
              nodeCursorStack.push({
                node = currentNode;
                kvIndex = childIndex;
              });
            };
            case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.dfsTraverseIter(), null child node error") };
          };
        }
      }
    }
  };



  // Intermediate result used during the scanning of different BTree node types
  type IntermediateScanResult<K, V> = {
    // the buffer scan result from a specific node
    resultBuffer: Buffer.Buffer<(K, V)>; 
    // the remaining limit
    limit: Nat;
    // the next key (applicable if limit was hit, but more entries exist)
    nextKey: ?K;
  };

  func iterScanLimit<K, V>(node: Node<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, dir: Direction, limit: Nat): IntermediateScanResult<K, V> {
    switch(dir, node) {
      case (#fwd, #leaf(leafNode)) {
        iterScanLimitLeafForward<K, V>(leafNode, compare, lowerBound, upperBound, limit);
      };
      case (#bwd, #leaf(leafNode)) {
        iterScanLimitLeafReverse<K, V>(leafNode, compare, lowerBound, upperBound, limit);
      };
      case (#fwd, #internal(internalNode)) {
        iterScanLimitInternalForward<K, V>(internalNode, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, limit: Nat);
      };
      case (#bwd, #internal(internalNode)) {
        iterScanLimitInternalReverse<K, V>(internalNode, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, limit: Nat);
      };
    }
  };

  func iterScanLimitLeafForward<K, V>({ data }: Leaf<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, limit: Nat): IntermediateScanResult<K, V> {
    let resultBuffer: Buffer.Buffer<(K, V)> = Buffer.Buffer(0);
    var remainingLimit = limit;
    var elementIndex = switch(BS.binarySearchNode(data.kvs, compare, lowerBound, data.count)) {
      case (#keyFound(idx)) { idx };
      case (#notFound(idx)) { 
        // skip this leaf if lower bound is greater than all elements in the leaf
        if (idx >= data.count) { 
          return {
            resultBuffer;
            limit = remainingLimit;
            nextKey = null;
          }
        };
        idx 
      };
    };

    label l while (remainingLimit > 1) {
      switch(data.kvs[elementIndex]) {
        case (?(k, v)) {
          switch(compare(k, upperBound)) {
            // iterating forward and key is greater than the upper bound
            // Set the limit to 0 and return the buffer to signal stopping the scan in the calling context. There is no next key
            case (#greater) { 
              return {
                resultBuffer;
                limit = 0;
                nextKey = null;
              }
            };
            // Key is equal to the upper bound. Add the element to the buffer, then set the limit to 0 and return the buffer to signal stopping the scan in the calling context. There is no next key
            case (#equal) {
              resultBuffer.add((k, v));
              return {
                resultBuffer;
                limit = 0;
                nextKey = null;
              }
            };
            // Iterating forward and key is less than the upper bound. Add the element to the buffer, decrement from the limit, and increase the element index
            case (#less) {
              resultBuffer.add((k, v));
              remainingLimit -= 1;
              elementIndex += 1;
              if (elementIndex >= data.count) { break l };
            };
          }
        };
        case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In iterScanLimitLeafForward, attemmpted to add a null element to the result buffer") };
      };
    };

    // if added all elements in the leaf, return the buffer and remaining limit
    if (elementIndex == data.count) {
      return {
        resultBuffer;
        limit = remainingLimit;
        nextKey = null;
      };
    };

    // otherwise, the remaining limit must equal 1 and we haven't gone through all of the elements in the leaf, set the next key and limit to 0, and return the buffer to signal stopping the scan in the calling context
    if (remainingLimit == 1) {
      return {
        resultBuffer;
        limit = 0;
        nextKey = switch(data.kvs[elementIndex]) {
          case null { null };
          case (?kv) {
            switch(compare(kv.0, upperBound)) {
              // if the next key is greater than the upper bound, have hit the upper bound, so return null
              case (#greater) { null };
              // otherwise less or equal to the upper bound, so return the next key
              case _ { ?kv.0 };
            };
          };
        };
      };
    };

    Debug.trap("UNREACHABLE_ERROR: file a bug report! In iterScanLimitLeafForward, reached a catch-all case that should not happen with a remaining limit =" # Nat.toText(remainingLimit));
  };

  
  func iterScanLimitLeafReverse<K, V>({ data }: Leaf<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, limit: Nat): IntermediateScanResult<K, V> {
    let resultBuffer: Buffer.Buffer<(K, V)> = Buffer.Buffer(0);
    var remainingLimit = limit;
    var elementIndex = switch(BS.binarySearchNode(data.kvs, compare, upperBound, data.count)) {
      case (#keyFound(idx)) { idx };
      case (#notFound(idx)) { 
        // skip this leaf if upper bound is less than all elements in the leaf
        if (idx == 0) { 
          return {
            resultBuffer;
            limit = remainingLimit;
            nextKey = null;
          }
        };

        // We are iterating in reverse and did not find the upper bound, choose the previous element
        // idx is not 0, so we can safely subtract 1
        idx - 1: Nat;
      };
    };

    label l while (remainingLimit > 1) {
      switch(data.kvs[elementIndex]) {
        case (?(k, v)) {
          switch(compare(k, lowerBound)) {
            // Iterating in reverse and key is less than the lower bound.
            // Set the limit to 0 and return the buffer to signal stopping the scan in the calling context. There is no next key
            case (#less) { 
              return {
                resultBuffer;
                limit = 0;
                nextKey = null;
              }
            };
            // Key is equal to the lower bound. Add the element to the buffer, then set the limit to 0 and return the buffer to signal stopping the scan in the calling context. There is no next key
            case (#equal) {
              resultBuffer.add((k, v));
              return {
                resultBuffer;
                limit = 0;
                nextKey = null;
              }
            };
            // Iterating in reverse and key is greater than the lower bound. Add the element to the buffer, decrement from the limit, and decrement the element index
            case (#greater) {
              resultBuffer.add((k, v));
              remainingLimit -= 1;
              // if this was the last element of the leaf, return the buffer and remaining limit)
              if (elementIndex == 0) {
                return {
                  resultBuffer;
                  limit = remainingLimit;
                  nextKey = null;
                }
              };
              elementIndex -= 1;
            }
          }
        };
        case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In iterScanLimitLeafReverse, attemmpted to add a null element to the result buffer") };
      };
    };

    if (remainingLimit > 1) {
      return {
        resultBuffer;
        limit = remainingLimit;
        nextKey = null;
      };
    };

    // otherwise, the remaining limit must equal 1 and we haven't gone through all of the elements in the leaf, set the next key and limit to 0, and return the buffer to signal stopping the scan in the calling context
    if (remainingLimit == 1) {
      return {
        resultBuffer;
        limit = 0;
        nextKey = switch(data.kvs[elementIndex]) {
          case null { null };
          case (?kv) { ?kv.0 };
        };
      };
    };

    Debug.trap("UNREACHABLE_ERROR: file a bug report! In iterScanLimitLeafReverse, reached a catch-all case that should not happen with a remaining limit =" # Nat.toText(remainingLimit));
  };


  // Cursor of the next key value pair in the internal node to explore from
  type ScanCursor<K, V> = { #leafCursor: Leaf<K, V>; #internalCursor: InternalCursor<K, V> };
  // An Internal Cursor used to keep track of the kv index being iterated upon within an internal node
  type InternalCursor<K, V> = {
    internal: Internal<K, V>;
    kvIndex: Nat;
  };

  func iterScanLimitInternalForward<K, V>(internal: Internal<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, limit: Nat): IntermediateScanResult<K, V> {
    // keep in mind that the limit has a + 1; (this additional 1 is for the nextKey)
    var remainingLimit = limit;
    // result buffer being appended to
    let resultBuffer: Buffer.Buffer<(K, V)> = Buffer.Buffer(0);
    // the next key to be returned
    var nextKey: ?K = null;
    // seed the initial node stack used to iterate throught the BTree
    let nodeStack = seedInitialCursorStack<K, V>(internal, compare, lowerBound, upperBound, #fwd, remainingLimit);

    label l while (remainingLimit > 0) {
      switch(nodeStack.pop()) {
        case (?#leafCursor(leaf)) {
          let intermediateScanResult = iterScanLimitLeafForward(leaf, compare, lowerBound, upperBound, remainingLimit);
          resultBuffer.append(intermediateScanResult.resultBuffer);
          remainingLimit := intermediateScanResult.limit;
          nextKey := intermediateScanResult.nextKey;
        };
        case (?#internalCursor(internalCursor)) {
          let poppedInternalKV = switch(internalCursor.internal.data.kvs[internalCursor.kvIndex]) {
            case (?kv) { kv };
            case null { 
              Debug.trap(
                "UNREACHABLE_ERROR: file a bug report! In iterScanLimitInternalForward, a popped #internalCursor has an invalid kvIndex. the internal returned has internal node count=" # Nat.toText(internalCursor.internal.data.count) # 
                " and index=" # Nat.toText(internalCursor.kvIndex)
              )
            };
          };
          switch(compare(
            poppedInternalKV.0,
            upperBound
          )) {
            case (#less) { 
              if (remainingLimit == 1) {
                return {
                  resultBuffer;
                  limit = 0;
                  nextKey = ?poppedInternalKV.0
                };
              };

              resultBuffer.add(poppedInternalKV);
              remainingLimit -= 1;

              // move the cursor to the kv to the right (greater)
              let childCursor = {
                internal = internalCursor.internal;
                kvIndex = internalCursor.kvIndex + 1;
              };

              // if not at the end of the internal node's kvs, push the next internal cursor kv to the stack
              if (internalCursor.kvIndex < (internalCursor.internal.data.count - 1: Nat)) {
                nodeStack.push(#internalCursor(childCursor));
              };

              // Then traverse from the new cursor's child predecessor
              traverse<K, V>(nodeStack, childCursor, compare, lowerBound, upperBound, #fwd, remainingLimit)
            };
            // add this kv and then are done
            case (#equal) { 
              if (remainingLimit == 1) {
                return {
                  resultBuffer;
                  limit = 0;
                  nextKey = ?poppedInternalKV.0
                };
              }; 

              resultBuffer.add(poppedInternalKV);
              remainingLimit -= 1;
              return {
                resultBuffer;
                limit = remainingLimit;
                nextKey = null;
              };
            };
            // have reached the end, we are done
            case (#greater) {
              return {
                resultBuffer;
                limit = remainingLimit;
                nextKey = null;
              };
            };
          }
        };
        // if no more nodes left in the stack to pop, return the result
        case null {
          return {
            resultBuffer;
            limit = remainingLimit;
            nextKey = null;
          };
        }
      } 
    }; 

    return {
      resultBuffer;
      limit = remainingLimit;
      nextKey;
    };

    Debug.trap("UNREACHABLE_ERROR: file a bug report! In iterScanLimitInternalForward, breached the scan loop without first returning a result.");
  };

  func iterScanLimitInternalReverse<K, V>(internal: Internal<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, limit: Nat): IntermediateScanResult<K, V> {
    // keep in mind that the limit has a + 1; (this additional 1 is for the nextKey)
    var remainingLimit = limit;
    // result buffer being appended to
    let resultBuffer: Buffer.Buffer<(K, V)> = Buffer.Buffer(0);
    // the next key to be returned
    var nextKey: ?K = null;
    // seed the initial node stack used to iterate throught the BTree
    let nodeStack = seedInitialCursorStack<K, V>(internal, compare, lowerBound, upperBound, #bwd, remainingLimit);

    label l while (remainingLimit > 0) {
      // pop the next node "cursor" from the stack
      switch(nodeStack.pop()) {
        case (?#leafCursor(leaf)) { 
          let intermediateScanResult = iterScanLimitLeafReverse(leaf, compare, lowerBound, upperBound, remainingLimit);
          resultBuffer.append(intermediateScanResult.resultBuffer);
          remainingLimit := intermediateScanResult.limit;
          nextKey := intermediateScanResult.nextKey;
        };
        case (?#internalCursor(internalCursor)) {
          let poppedInternalKV = switch(internalCursor.internal.data.kvs[internalCursor.kvIndex]) {
            case (?kv) { kv };
            case null { 
              Debug.trap(
                "UNREACHABLE_ERROR: file a bug report! In iterScanLimitInternalReverse, a popped #internalCursor has an invalid kvIndex. the internal returned has internal node count=" # Nat.toText(internalCursor.internal.data.count) # 
                " and index=" # Nat.toText(internalCursor.kvIndex)
              )
            };
          };

          switch(compare(
            poppedInternalKV.0,
            lowerBound 
          )) {
            case (#greater) { 
              // if one spot left, the popped kv contains the next key
              if (remainingLimit == 1) {
                return {
                  resultBuffer;
                  limit = 0;
                  nextKey = ?poppedInternalKV.0
                };
              };

              resultBuffer.add(poppedInternalKV);
              remainingLimit -= 1;
              let childCursor = {
                internal = internalCursor.internal;
                kvIndex = internalCursor.kvIndex;
              };
              // if not at the last kv of this internal node, move the cursor to the left (less) and push it to the stack
              if (internalCursor.kvIndex > 0) {
                nodeStack.push(#internalCursor({ childCursor with kvIndex = internalCursor.kvIndex - 1: Nat }));
              };

              // traverse the childCursor
              traverse<K, V>(nodeStack, childCursor, compare, lowerBound, upperBound, #bwd, remainingLimit)
            };
            // add this kv and then are done
            case (#equal) { 
              if (remainingLimit == 1) {
                return {
                  resultBuffer;
                  limit = 0;
                  nextKey = ?poppedInternalKV.0
                };
              }; 

              resultBuffer.add(poppedInternalKV);
              remainingLimit -= 1;
              return {
                resultBuffer;
                limit = remainingLimit;
                nextKey = null;
              };
            };
            // have reached the end, we are done
            case (#less) {
              return {
                resultBuffer;
                limit = remainingLimit;
                nextKey = null;
              };
            };
          }
        };
        // if no more nodes left in the stack to pop, return the result
        case null {
          return {
            resultBuffer;
            limit = remainingLimit;
            nextKey = null;
          };
        }
      } 
    }; 

    return {
      resultBuffer;
      limit = remainingLimit;
      nextKey;
    };

    Debug.trap("UNREACHABLE_ERROR: file a bug report! In iterScanLimitInternalReverse, breached the scan loop without first returning a result.");
  };

  func seedInitialCursorStack<K, V>(internal: Internal<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, dir: Direction, limit: Nat): Stack.Stack<ScanCursor<K, V>> {
    // stack of internal nodes coupled with the next node index
    var nodeStack = Stack.Stack<ScanCursor<K, V>>();
    // the bound to compare against when traversing
    let traversalBound = switch(dir) {
      case (#fwd) { lowerBound };
      case (#bwd) { upperBound };
    };
    // child index closest to bound
    let childIndex = switch(BS.binarySearchNode(internal.data.kvs, compare, traversalBound, internal.data.count)) {
      // if found the lower bound key, then add the node and return the node stack (to be the next node popped)
      case (#keyFound(kvIndex)) { 
        nodeStack.push(#internalCursor({ internal; kvIndex }));
        return nodeStack;
      };
      // otherwise, the index returned is that of the child
      case (#notFound(childIdx)) { childIdx };
    };

    var childCursor = {
      internal;
      kvIndex = childIndex;
    };

    switch(dir) {
      case (#fwd) {
        // if child index is not the last child, push the internal and next kv index onto the stack (to be popped later)
        // Note: the child index is equal to the internal node's next kv index in this case, so we can use that here
        if (childIndex < internal.data.count) {
          nodeStack.push(#internalCursor(childCursor));
        };
      };
      case (#bwd) {
        // if child index is not the first child, push the internal and previous kv index onto the stack (to be popped later)
        // Note: the child index - 1 is equal to the internal node's previous kv index in this case, so we can use that here
        if (childIndex > 0) {
          nodeStack.push(#internalCursor({ childCursor with kvIndex = (childIndex - 1: Nat) }));
        };
      }
    };

    // continue traversing the BTree and adding cursors to the stack until the node with the element closest to the lower bound is pushed
    traverse(nodeStack, childCursor, compare, lowerBound, upperBound, dir, limit);
    nodeStack;
  };

  func traverse<K, V>(nodeStack: Stack.Stack<ScanCursor<K, V>>, internalCursor: InternalCursor<K, V>, compare: (K, K) -> O.Order, lowerBound: K, upperBound: K, dir: Direction, limit: Nat): () {
    // the current internal node being explored
    var currentNode = internalCursor.internal;
    // the kv index of the current internal node being explored
    var childIndex = internalCursor.kvIndex;
    // the bound to compare against when traversing
    let traversalBound = switch(dir) {
      case (#fwd) { lowerBound };
      case (#bwd) { upperBound };
    };

    label l loop {
      switch(currentNode.children[childIndex]) {
        // if the child is an internal node, update the current node for the next traversal loop
        case (?#internal(internalNode)) { currentNode := internalNode };
        // if the child is a leaf node, push it to the stack and return the stack (reached the end of this path)
        case (?#leaf(leafNode)) { nodeStack.push(#leafCursor(leafNode)); return };
        case null {
          Debug.trap(
            "UNREACHABLE_ERROR: file a bug report! In BTree.traverse(), encountered a null and invalid childIndex=" # Nat.toText(childIndex) #
            "for an internal node with count=" # Nat.toText(currentNode.data.count)
          );
        };
      };

      // update the child index (for the next node to traverse)
      childIndex := switch(BS.binarySearchNode(currentNode.data.kvs, compare, traversalBound, currentNode.data.count)) {
        // if found the bound key, then add the node and return the node stack (to be the next node popped)
        case (#keyFound(kvIndex)) { 
          nodeStack.push(#internalCursor({ internal = currentNode; kvIndex }));
          return;
        };
        // otherwise, the index returned is that of the child
        case (#notFound(childIdx)) { childIdx };
      };

      // depending on the order of traversal, push the appropriate internal cursor to the stack
      // (as long as the cursor is not at the end of that current internal node)
      switch(dir) {
        case (#fwd) {
          // if child index is not the last child, push the internal and next kv index onto the stack (to be popped later)
          // Note: the child index is equal to the internal node's next kv index in this case, so we can use that here
          if (childIndex < currentNode.data.count) {
            nodeStack.push(#internalCursor({
              internal = currentNode;
              kvIndex = childIndex;
            }));
          };
        };
        case (#bwd) {
          // if child index is not the last child, push the internal and next kv index onto the stack (to be popped later)
          // Note: the child index is equal to the internal node's next kv index in this case, so we can use that here
          if (childIndex > 0) {
            nodeStack.push(#internalCursor({
              internal = currentNode;
              kvIndex = childIndex - 1;
            }));
          };
        }
      }
    };
  };


  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateInternalDeleteResult<K, V> = {
    // element was deleted or not found, returning the old value (?value or null)
    #delete: ?V;
    // deleted an element, but was unable to successfully borrow and rebalance at the previous level without merging children
    // the internalChild is the merged child that needs to be rebalanced at the next level up in the BTree
    #mergeChild: {
      internalChild: Internal<K, V>;
      deletedValue: ?V
    }
  };

  func internalDeleteHelper<K, V>(internalNode: Internal<K, V>, order: Nat, compare: (K, K) -> O.Order, deleteKey: K, skipNode: Bool): IntermediateInternalDeleteResult<K, V> {
    let minKeys = NU.minKeysFromOrder(order);
    let keyIndex = NU.getKeyIndex<K, V>(internalNode.data, compare, deleteKey);

    // match on both the result of the node binary search, and if this node level should be skipped even if the key is found (internal kv replacement case)
    switch(keyIndex, skipNode) {
      // if key is found in the internal node
      case (#keyFound(deleteIndex), false) {
        let deletedValue = switch(internalNode.data.kvs[deleteIndex]) {
          case (?kv) { ?kv.1 };
          case null { assert false; null };
        };
        // TODO: (optimization) replace with deletion in one step without having to retrieve the maxKey first
        let replaceKV = NU.getMaxKeyValue(internalNode.children[deleteIndex]);
        internalNode.data.kvs[deleteIndex] := ?replaceKV;
        switch(internalDeleteHelper(internalNode, order, compare, replaceKV.0, true)) {
          case (#delete(_)) { #delete(deletedValue) };
          case (#mergeChild({ internalChild; })) { #mergeChild({ internalChild; deletedValue }) }
        };
      };
      // if key is not found in the internal node OR the key is found, but skipping this node (because deleting the in order precessor i.e. replacement kv)
      // in both cases need to descend and traverse to find the kv to delete
      case ((#keyFound(_), true) or (#notFound(_), _)) {
        let childIndex = switch(keyIndex) {
          case (#keyFound(replacedSkipKeyIndex)) { replacedSkipKeyIndex };
          case (#notFound(childIndex)) { childIndex };
        };
        let child = switch(internalNode.children[childIndex]) {
          case (?c) { c };
          case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalDeleteHelper, child index of #keyFound or #notfound is null") };
        };
        switch(child) {
          // if child is internal
          case (#internal(internalChild)) { 
            switch(internalDeleteHelper(internalChild, order, compare, deleteKey, false), childIndex == 0) {
              // if value was successfully deleted and no additional tree re-balancing is needed, return the deleted value
              case (#delete(v), _) { #delete(v) };
              // if internalChild needs rebalancing and pulling child is left most
              case (#mergeChild({ internalChild; deletedValue }), true) {
                // try to pull left-most key and child from right sibling
                switch(NU.borrowFromInternalSibling(internalNode.children, childIndex + 1, #successor)) {
                  // if can pull up sibling kv and child
                  case (#borrowed({ deletedSiblingKVPair; child; })) {
                    NU.rotateBorrowedKVsAndChildFromSibling(
                      internalNode,
                      childIndex,
                      deletedSiblingKVPair,
                      child,
                      internalChild,
                      #right
                    );
                    #delete(deletedValue);
                  };
                  // unable to pull from sibling, need to merge with right sibling and push down parent
                  case (#notEnoughKeys(sibling)) {
                    // get the parent kv that will be pushed down the the child
                    let kvPairToBePushedToChild = ?AU.deleteAndShiftValuesOver(internalNode.data.kvs, 0);
                    internalNode.data.count -= 1;
                    // merge the children and push down the parent
                    let newChild = NU.mergeChildrenAndPushDownParent<K, V>(internalChild, kvPairToBePushedToChild, sibling);
                    // update children of the parent
                    internalNode.children[0] := ?#internal(newChild);
                    ignore ?AU.deleteAndShiftValuesOver(internalNode.children, 1);
                    
                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue; })
                    } else {
                      #delete(deletedValue)
                    }
                  };
                }
              };
              // if internalChild needs rebalancing and pulling child is > 0, so a left sibling exists
              case (#mergeChild({ internalChild; deletedValue }), false) {
                // try to pull right-most key and its child directly from left sibling
                switch(NU.borrowFromInternalSibling(internalNode.children, childIndex - 1: Nat, #predecessor)) {
                  case (#borrowed({ deletedSiblingKVPair; child; })) {
                    NU.rotateBorrowedKVsAndChildFromSibling(
                      internalNode,
                      childIndex - 1: Nat,
                      deletedSiblingKVPair,
                      child,
                      internalChild,
                      #left
                    );
                    #delete(deletedValue);
                  };
                  // unable to pull from left sibling
                  case (#notEnoughKeys(leftSibling)) {
                    // if child is not last index, try to pull from the right child
                    if (childIndex < internalNode.data.count) {
                      switch(NU.borrowFromInternalSibling(internalNode.children, childIndex, #successor)) {
                        // if can pull up sibling kv and child
                        case (#borrowed({ deletedSiblingKVPair; child; })) {
                          NU.rotateBorrowedKVsAndChildFromSibling(
                            internalNode,
                            childIndex,
                            deletedSiblingKVPair,
                            child,
                            internalChild,
                            #right
                          );
                          return #delete(deletedValue);
                        };
                        // if cannot borrow, from left or right, merge (see below)
                        case _ {};
                      }
                    };

                    // get the parent kv that will be pushed down the the child
                    let kvPairToBePushedToChild = ?AU.deleteAndShiftValuesOver(internalNode.data.kvs, childIndex - 1: Nat);
                    internalNode.data.count -= 1;
                    // merge it the children and push down the parent 
                    let newChild = NU.mergeChildrenAndPushDownParent(leftSibling, kvPairToBePushedToChild, internalChild);

                    // update children of the parent
                    internalNode.children[childIndex - 1] := ?#internal(newChild);
                    ignore ?AU.deleteAndShiftValuesOver(internalNode.children, childIndex);
                    
                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue; })
                    } else {
                      #delete(deletedValue)
                    };
                  }
                }
              };
            }
          };
          // if child is leaf
          case (#leaf(leafChild)) { 
            switch(leafDeleteHelper(leafChild, order, compare, deleteKey), childIndex == 0) {
              case (#delete(value), _) { #delete(value)};
              // if delete child is left most, try to borrow from right child
              case (#mergeLeafData({ data; leafDeleteIndex }), true) { 
                switch(NU.borrowFromRightLeafChild(internalNode.children, childIndex)) {
                  case (?borrowedKVPair) {
                    let kvPairToBePushedToChild = internalNode.data.kvs[childIndex];
                    internalNode.data.kvs[childIndex] := ?borrowedKVPair;
                    
                    let deletedKV = AU.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, leafChild.data.count - 1, leafDeleteIndex);
                    #delete(?deletedKV.1);
                  };

                  case null { 
                    // can't borrow from right child, delete from leaf and merge with right child and parent kv, then push down into new leaf
                    let rightChild = switch(internalNode.children[childIndex + 1]) {
                      case (?#leaf(rc)) { rc};
                      case _ { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalDeleteHelper, if trying to borrow from right leaf child is null, rightChild index cannot be null or internal") };
                    };
                    let (mergedLeaf, deletedKV) = mergeParentWithLeftRightChildLeafNodesAndDelete(
                      internalNode.data.kvs[childIndex],
                      leafChild,
                      rightChild,
                      leafDeleteIndex,
                      #left
                    );
                    // delete the left most internal node kv, since was merging from a deletion in left most child (0) and the parent kv was pushed into the mergedLeaf
                    ignore AU.deleteAndShiftValuesOver<(K, V)>(internalNode.data.kvs, 0);
                    // update internal node children
                    AU.replaceTwoWithElementAndShift<Node<K, V>>(internalNode.children, #leaf(mergedLeaf), 0);
                    internalNode.data.count -= 1;

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue = ?deletedKV.1 })
                    } else {
                      #delete(?deletedKV.1)
                    }

                  }
                }
              };
              // if delete child is middle or right most, try to borrow from left child
              case (#mergeLeafData({ data; leafDeleteIndex }), false) { 
                // if delete child is right most, try to borrow from left child
                switch(NU.borrowFromLeftLeafChild(internalNode.children, childIndex)) {
                  case (?borrowedKVPair) {
                    let kvPairToBePushedToChild = internalNode.data.kvs[childIndex - 1];
                    internalNode.data.kvs[childIndex - 1] := ?borrowedKVPair;
                    let kvDelete = AU.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, 0, leafDeleteIndex);
                    #delete(?kvDelete.1);
                  };
                  case null {
                    // if delete child is in the middle, try to borrow from right child
                    if (childIndex < internalNode.data.count) {
                      // try to borrow from right
                      switch(NU.borrowFromRightLeafChild(internalNode.children, childIndex)) {
                        case (?borrowedKVPair) {
                          let kvPairToBePushedToChild = internalNode.data.kvs[childIndex];
                          internalNode.data.kvs[childIndex] := ?borrowedKVPair;
                          // insert the successor at the very last element
                          let kvDelete = AU.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, leafChild.data.count-1, leafDeleteIndex);
                          return #delete(?kvDelete.1);
                        };
                        // if cannot borrow, from left or right, merge (see below)
                        case _ {}
                      }
                    };

                    // can't borrow from left child, delete from leaf and merge with left child and parent kv, then push down into new leaf
                    let leftChild = switch(internalNode.children[childIndex - 1]) {
                      case (?#leaf(lc)) { lc};
                      case _ { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalDeleteHelper, if trying to borrow from left leaf child is null, then left child index must not be null or internal") };
                    };
                    let (mergedLeaf, deletedKV) = mergeParentWithLeftRightChildLeafNodesAndDelete(
                      internalNode.data.kvs[childIndex-1],
                      leftChild,
                      leafChild,
                      leafDeleteIndex,
                      #right
                    );
                    // delete the right most internal node kv, since was merging from a deletion in the right most child and the parent kv was pushed into the mergedLeaf
                    ignore AU.deleteAndShiftValuesOver<(K, V)>(internalNode.data.kvs, childIndex - 1);
                    // update internal node children
                    AU.replaceTwoWithElementAndShift<Node<K, V>>(internalNode.children, #leaf(mergedLeaf), childIndex - 1);
                    internalNode.data.count -= 1;

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue = ?deletedKV.1 })
                    } else {
                      #delete(?deletedKV.1)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  };


  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateLeafDeleteResult<K, V> = {
    // element was deleted or not found, returning the old value (?value or null)
    #delete: ?V;
    // leaf had the minimum number of keys when deleting, so returns the leaf node's data and the index of the key that will be deleted
    #mergeLeafData: {
      data: Data<K, V>;
      leafDeleteIndex: Nat;
    }
  };

  func leafDeleteHelper<K, V>(leafNode: Leaf<K, V>, order: Nat, compare: (K, K) -> O.Order, deleteKey: K): IntermediateLeafDeleteResult<K, V> {
    let minKeys = NU.minKeysFromOrder(order);

    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, deleteKey)) {
      case (#keyFound(deleteIndex)) {
        if (leafNode.data.count > minKeys) {
          leafNode.data.count -= 1;
          #delete(?AU.deleteAndShiftValuesOver<(K, V)>(leafNode.data.kvs, deleteIndex).1)
        } else {
          #mergeLeafData({
            data = leafNode.data;
            leafDeleteIndex = deleteIndex;
          });
        }
      };
      case (#notFound(_)) {
        #delete(null)
      }
    }
  };


  // get helper if internal node
  func getFromInternal<K, V>(internalNode: Internal<K, V>, compare: (K, K) -> O.Order, key: K): ?V { 
    switch(NU.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(index)) { getExistingValueFromIndex(internalNode.data, index) };
      case (#notFound(index)) {
        switch(internalNode.children[index]) {
          // expects the child to be there, otherwise there's a bug in binary search or the tree is invalid
          case null { assert false; null };
          case (?#leaf(leafNode)) { getFromLeaf(leafNode, compare, key)};
          case (?#internal(internalNode)) { getFromInternal(internalNode, compare, key)}
        }
      }
    }
  };

  // get function helper if leaf node
  func getFromLeaf<K, V>(leafNode: Leaf<K, V>, compare: (K, K) -> O.Order, key: K): ?V { 
    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(index)) { getExistingValueFromIndex(leafNode.data, index) };
      case _ null;
    }
  };

  // get function helper that retrieves an existing value in the case that the key is found
  func getExistingValueFromIndex<K, V>(data: Data<K, V>, index: Nat): ?V {
    switch(data.kvs[index]) {
      case null { null };
      case (?ov) { ?ov.1 }
    }
  };


  // which child the deletionIndex is referring to
  type DeletionSide = { #left; #right; }; 
  
  func mergeParentWithLeftRightChildLeafNodesAndDelete<K, V>(
    parentKV: ?(K, V),
    leftChild: Leaf<K, V>,
    rightChild: Leaf<K, V>,
    deleteIndex: Nat,
    deletionSide: DeletionSide
  ): (Leaf<K, V>, (K, V)) {
    let count = leftChild.data.count * 2;
    let (kvs, deletedKV) = AU.mergeParentWithChildrenAndDelete<(K, V)>(
      parentKV,
      leftChild.data.count,
      leftChild.data.kvs,
      rightChild.data.kvs,
      deleteIndex,
      deletionSide
    );
    (
      {
        data = {
          kvs; 
          var count = count
        }
      },
      deletedKV
    )
  };


  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateInsertResult<K, V> = {
    // element was inserted or replaced, returning the old value (?value or null)
    #insert: ?V;
    // child was full when inserting, so returns the promoted kv pair and the split left and right child 
    #promote: {
      kv: (K, V);
      leftChild: Node<K, V>;
      rightChild: Node<K, V>;
    };
  };


  // Helper for inserting into a leaf node
  func leafInsertHelper<K, V>(leafNode: Leaf<K, V>, order: Nat, compare: (K, K) -> O.Order, key: K, value: V): (IntermediateInsertResult<K, V>) {
    // Perform binary search to see if the element exists in the node
    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = leafNode.data.kvs[insertIndex];
        leafNode.data.kvs[insertIndex] := ?(key, value);
        switch(previous) {
          case (?ov) { #insert(?ov.1) };
          case null { assert false; #insert(null) }; // the binary search already found an element, so this case should never happen
        }
      };
      case (#notFound(insertIndex)) {
        // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
        let maxKeys: Nat = order - 1;
        // If the leaf is full, insert, split the node, and promote the middle element
        if (leafNode.data.count >= maxKeys) {
          let (leftKVs, promotedParentElement, rightKVs) = AU.insertOneAtIndexAndSplitArray(
            leafNode.data.kvs,
            (key, value),
            insertIndex
          );

          let leftCount = order / 2;
          let rightCount: Nat = if (order % 2 == 0) { leftCount - 1 } else { leftCount };

          (
            #promote({
              kv = promotedParentElement;
              leftChild = createLeaf<K, V>(leftKVs, leftCount);
              rightChild = createLeaf<K, V>(rightKVs, rightCount);
            })
          )
        } 
        // Otherwise, insert at the specified index (shifting elements over if necessary) 
        else {
          NU.insertAtIndexOfNonFullNodeData<K, V>(leafNode.data, ?(key, value), insertIndex);
          #insert(null);
        };
      }
    }
  };


  // Helper for inserting into an internal node
  func internalInsertHelper<K, V>(internalNode: Internal<K, V>, order: Nat, compare: (K, K) -> O.Order, key: K, value: V): IntermediateInsertResult<K, V> {
    switch(NU.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = internalNode.data.kvs[insertIndex];
        internalNode.data.kvs[insertIndex] := ?(key, value);
        switch(previous) {
          case (?ov) { #insert(?ov.1) };
          case null { assert false; #insert(null) }; // the binary search already found an element, so this case should never happen
        }
      };
      case (#notFound(insertIndex)) {
        let insertResult = switch(internalNode.children[insertIndex]) {
          case null { assert false; #insert(null) };
          case (?#leaf(leafNode)) { leafInsertHelper(leafNode, order, compare, key, value) };
          case (?#internal(internalChildNode)) { internalInsertHelper(internalChildNode, order, compare, key, value) };
        };

        switch(insertResult) {
          case (#insert(ov)) { #insert(ov) };
          case (#promote({ kv; leftChild; rightChild; })) {
            // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
            let maxKeys: Nat = order - 1;
            // if current internal node is full, need to split the internal node
            if (internalNode.data.count >= maxKeys) {
              // insert and split internal kvs, determine new promotion target kv
              let (leftKVs, promotedParentElement, rightKVs) = AU.insertOneAtIndexAndSplitArray(
                internalNode.data.kvs,
                (kv),
                insertIndex
              );

              // calculate the element count in the left KVs and the element count in the right KVs
              let leftCount = order / 2;
              let rightCount: Nat = if (order % 2 == 0) { leftCount - 1 } else { leftCount };

              // split internal children
              let (leftChildren, rightChildren) = NU.splitChildrenInTwoWithRebalances<K, V>(
                internalNode.children,
                insertIndex,
                leftChild,
                rightChild
              );

              // send the kv to be promoted, as well as the internal children left and right split 
              #promote({
                kv = promotedParentElement;
                leftChild = #internal({
                  data = { kvs = leftKVs; var count = leftCount; };
                  children = leftChildren;
                });
                rightChild = #internal({
                  data = { kvs = rightKVs; var count = rightCount; };
                  children = rightChildren;
                })
              });
            }
            else {
              // insert the new kvs into the internal node
              NU.insertAtIndexOfNonFullNodeData(internalNode.data, ?kv, insertIndex);
              // split and re-insert the single child that needs rebalancing
              NU.insertRebalancedChild(internalNode.children, insertIndex, leftChild, rightChild);
              #insert(null);
            }
          }
        };
      }
    };
  };

  // TODO: Think if want to combine this with the leafInsertHelper
  // Helper for updating an element in a leaf node
  func leafUpdateHelper<K, V>(leafNode: Leaf<K, V>, order: Nat, compare: (K, K) -> O.Order, key: K, updateFunction: (?V) -> V): (IntermediateInsertResult<K, V>) {
    // Perform binary search to see if the element exists in the node
    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = leafNode.data.kvs[insertIndex];
        switch(previous) {
          case (?ov) { 
            leafNode.data.kvs[insertIndex] := ?(key, updateFunction(?ov.1));
            #insert(?ov.1)
          };
          // the binary search has already found an element, so this case should never happen
          case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In leafUpdateHelper, when matching on a #keyFound previous value, the previous kv turned out to be null") };
        }
      };
      case (#notFound(insertIndex)) {
        // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
        let maxKeys: Nat = order - 1;
        // If the leaf is full, insert, split the node, and promote the middle element
        if (leafNode.data.count >= maxKeys) {
          let (leftKVs, promotedParentElement, rightKVs) = AU.insertOneAtIndexAndSplitArray(
            leafNode.data.kvs,
            (key, updateFunction(null)),
            insertIndex
          );

          let leftCount = order / 2;
          let rightCount: Nat = if (order % 2 == 0) { leftCount - 1 } else { leftCount };

          (
            #promote({
              kv = promotedParentElement;
              leftChild = createLeaf<K, V>(leftKVs, leftCount);
              rightChild = createLeaf<K, V>(rightKVs, rightCount);
            })
          )
        } 
        // Otherwise, insert at the specified index (shifting elements over if necessary) 
        else {
          NU.insertAtIndexOfNonFullNodeData<K, V>(leafNode.data, ?(key, updateFunction(null)), insertIndex);
          #insert(null);
        };
      }
    }
  };

  // TODO: Think if want to combine this with the internalInsertHelper
  // Helper for inserting into an internal node
  func internalUpdateHelper<K, V>(internalNode: Internal<K, V>, order: Nat, compare: (K, K) -> O.Order, key: K, updateFunction: (?V) -> V): IntermediateInsertResult<K, V> {
    switch(NU.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = internalNode.data.kvs[insertIndex];
        switch(previous) {
          case (?ov) { 
            internalNode.data.kvs[insertIndex] := ?(key, updateFunction(?ov.1));
            #insert(?ov.1)
          };
          // the binary search has already found an element, so this case should never happen
          case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalUpdateHelper, when matching on a #keyFound previous value, the previous kv turned out to be null") };
        }
      };
      case (#notFound(insertIndex)) {
        let updateResult = switch(internalNode.children[insertIndex]) {
          case null { assert false; #insert(null) };
          case (?#leaf(leafNode)) { leafUpdateHelper(leafNode, order, compare, key, updateFunction) };
          case (?#internal(internalChildNode)) { internalUpdateHelper(internalChildNode, order, compare, key, updateFunction) };
        };

        switch(updateResult) {
          case (#insert(ov)) { #insert(ov) };
          case (#promote({ kv; leftChild; rightChild; })) {
            // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
            let maxKeys: Nat = order - 1;
            // if current internal node is full, need to split the internal node
            if (internalNode.data.count >= maxKeys) {
              // insert and split internal kvs, determine new promotion target kv
              let (leftKVs, promotedParentElement, rightKVs) = AU.insertOneAtIndexAndSplitArray(
                internalNode.data.kvs,
                (kv),
                insertIndex
              );

              // calculate the element count in the left KVs and the element count in the right KVs
              let leftCount = order / 2;
              let rightCount: Nat = if (order % 2 == 0) { leftCount - 1 } else { leftCount };

              // split internal children
              let (leftChildren, rightChildren) = NU.splitChildrenInTwoWithRebalances<K, V>(
                internalNode.children,
                insertIndex,
                leftChild,
                rightChild
              );

              // send the kv to be promoted, as well as the internal children left and right split 
              #promote({
                kv = promotedParentElement;
                leftChild = #internal({
                  data = { kvs = leftKVs; var count = leftCount; };
                  children = leftChildren;
                });
                rightChild = #internal({
                  data = { kvs = rightKVs; var count = rightCount; };
                  children = rightChildren;
                })
              });
            }
            else {
              // insert the new kvs into the internal node
              NU.insertAtIndexOfNonFullNodeData(internalNode.data, ?kv, insertIndex);
              // split and re-insert the single child that needs rebalancing
              NU.insertRebalancedChild(internalNode.children, insertIndex, leftChild, rightChild);
              #insert(null);
            }
          }
        };
      }
    };
  };

  func createLeaf<K, V>(kvs: [var ?(K, V)], count: Nat): Node<K, V> {
    #leaf({
      data = {
        kvs;
        var count;
      }
    })
  };

  /// Opinionated version of generating a textual representation of a BTree. Primarily to be used
  /// for testing and debugging
  public func toText<K, V>(t: BTree<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var textOutput = "BTree={";
    textOutput #= "root=" # rootToText<K, V>(t.root, keyToText, valueToText) # "; ";
    textOutput #= "size=" # Nat.toText(t.size) # "; ";
    textOutput #= "order=" # Nat.toText(t.order) # "; ";
    textOutput # "}";
  };


  /// Determines if two BTrees are equivalent
  public func equals<K, V>(
    t1: BTree<K, V>,
    t2: BTree<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    if (t1.order != t2.order or t1.size != t2.size) return false;

    nodeEquals(t1.root, t2.root, keyEquals, valueEquals);
  };


  func rootToText<K, V>(node: Node<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var rootText = "{";
    switch(node) {
      case (#leaf(leafNode)) { rootText #= "#leaf=" # leafToText(leafNode, keyToText, valueToText) };
      case (#internal(internalNode)) {
        rootText #= "#internal=" # internalToText(internalNode, keyToText, valueToText) 
      };
    }; 

    rootText;
  };

  func leafToText<K, V>(leaf: Leaf<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var leafText = "{data=";
    leafText #= dataToText(leaf.data, keyToText, valueToText); 
    leafText # "}";
  };

  func internalToText<K, V>(internal: Internal<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var internalText = "{";
    internalText #= "data=" # dataToText(internal.data, keyToText, valueToText) # "; ";
    internalText #= "children=[";

    var i = 0;
    while (i < internal.children.size()) {
      switch(internal.children[i]) {
        case null { internalText #= "null" };
        case (?(#leaf(leafNode))) { internalText #= "#leaf=" # leafToText(leafNode, keyToText, valueToText) };
        case (?(#internal(internalNode))) {
          internalText #= "#internal=" # internalToText(internalNode, keyToText, valueToText)
        };
      };
      internalText #= ", ";
      i += 1;
    };

    internalText # "]}";
  };

  func dataToText<K, V>(data: Data<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var dataText = "{kvs=[";
    var i = 0;
    while (i < data.kvs.size()) {
      switch(data.kvs[i]) {
        case null { dataText #= "null, " };
        case (?(k, v)) {
          dataText #= "(key={" # keyToText(k) # "}, value={" # valueToText(v) # "}), "
        }
      };

      i += 1;
    };

    dataText #= "]; count=" # Nat.toText(data.count) # ";}";
    dataText;
  };

  
  func nodeEquals<K, V>(
    n1: Node<K, V>,
    n2: Node<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    switch(n1, n2) {
      case (#leaf(l1), #leaf(l2)) { 
        dataEquals(l1.data, l2.data, keyEquals, valueEquals);
      };
      case (#internal(i1), #internal(i2)) {
        dataEquals(i1.data, i2.data, keyEquals, valueEquals)
        and
        childrenEquals(i1.children, i2.children, keyEquals, valueEquals)
      };
      case _ { false };
    };
  };

  func childrenEquals<K, V>(
    c1: [var ?Node<K, V>],
    c2: [var ?Node<K, V>],
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    if (c1.size() != c2.size()) { return false };

    var i = 0;
    while (i < c1.size()) {
      switch(c1[i], c2[i]) {
        case (null, null) {};
        case (?n1, ?n2) { 
          if (not nodeEquals(n1, n2, keyEquals, valueEquals)) {
            return false;
          }
        };
        case _ { return false }
      };

      i += 1;
    };

    true
  };

  func dataEquals<K, V>(
    d1: Data<K, V>,
    d2: Data<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    if (d1.count != d2.count) { return false };
    if (d1.kvs.size() != d2.kvs.size()) { return false };

    var i = 0;
    while(i < d1.kvs.size()) {
      switch(d1.kvs[i], d2.kvs[i]) {
        case (null, null) {};
        case (?(k1, v1), ?(k2, v2)) {
          if (
            (not keyEquals(k1, k2))
            or
            (not valueEquals(v1, v2))
          ) { return false };
        };
        case _ { return false };
      };

      i += 1;
    };

    true;
  };

}