import AU "./ArrayUtil";
import BS "./BinarySearch";
import Types "./Types";

import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Nat "mo:base/Nat";


module {

  /// Inserts element at the given index into a non-full leaf node
  public func insertAtIndexOfNonFullNodeData<K, V>(data: Types.Data<K, V>, kvPair: ?(K, V), insertIndex: Nat): () {
    let currentLastElementIndex: Nat = if (data.count == 0) { 0 } else { data.count - 1 };
    AU.insertAtPosition<(K, V)>(data.kvs, kvPair, insertIndex, currentLastElementIndex);

    // increment the count of data in this node since just inserted an element
    data.count += 1;
  };

  /// Inserts two rebalanced (split) child halves into a non-full array of children. 
  public func insertRebalancedChild<K, V>(children: [var ?Types.Node<K, V>], rebalancedChildIndex: Nat, leftChildInsert: Types.Node<K, V>, rightChildInsert: Types.Node<K, V>): () {
    // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
    var j: Nat = children.size() - 2;

    // This is just a sanity check to ensure the children aren't already full (should split promote otherwise)
    // TODO: Remove this check once confident
    if (Option.isSome(children[j+1])) { assert false }; 

    // Iterate backwards over the array and shift each element over to the right by one until the rebalancedChildIndex is hit
    while (j > rebalancedChildIndex) {
      children[j + 1] := children[j];
      j -= 1;
    };

    // Insert both the left and right rebalanced children (replacing the pre-split child)
    children[j] := ?leftChildInsert;
    children[j+1] := ?rightChildInsert;
  };

  /// Used when splitting the children of an internal node
  ///
  /// Takes in the rebalanced child index, as well as both halves of the rebalanced child and splits the children, inserting the left and right child halves appropriately
  ///
  /// For more context, see the documentation for the splitArrayAndInsertTwo method in ArrayUtils.mo
  public func splitChildrenInTwoWithRebalances<K, V>(
    children: [var ?Types.Node<K, V>],
    rebalancedChildIndex: Nat,
    leftChildInsert: Types.Node<K, V>,
    rightChildInsert: Types.Node<K, V>
  ): ([var ?Types.Node<K, V>], [var ?Types.Node<K, V>]) {
    AU.splitArrayAndInsertTwo<Types.Node<K, V>>(children, rebalancedChildIndex, leftChildInsert, rightChildInsert);
  };

  /// Helper used to get the key index of of a key within a node
  ///
  /// for more, see the BinarySearch.binarySearchNode() documentation
  public func getKeyIndex<K, V>(data: Types.Data<K, V>, compare: (K, K) -> Order.Order, key: K): BS.SearchResult {
    BS.binarySearchNode<K, V>(data.kvs, compare, key, data.count);
  };

  // calculates a BTree Node's minimum allowed keys given the order of the BTree
  public func minKeysFromOrder(order: Nat): Nat {
    if (Nat.rem(order, 2) == 0) { order / 2 - 1} 
    else { order / 2 }
  };

  // Given a node, get the maximum key value (right most leaf kv)
  public func getMaxKeyValue<K, V>(node: ?Types.Node<K, V>): (K, V) {
    switch(node) {
      case (?#leaf({ data; })) { 
        switch(data.kvs[data.count - 1]) {
          case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In getMaxKeyValue, data cannot have more elements than it's count") };
          case (?kv) { kv }
        };
      };
      case (?#internal({ data; children })) { getMaxKeyValue(children[data.count]) };
      case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In getMaxKeyValue, the node provided cannot be null") };
    }
  };


  type InorderBorrowType = {
    #predecessor;
    #successor;
  };

  // attempts to retrieve the in max key of the child leaf node directly to the left if the node will allow it
  // returns the deleted max key if able to retrieve, null if not able
  //
  // mutates the predecessing node's keys
  public func borrowFromLeftLeafChild<K, V>(children: [var ?Types.Node<K, V>], ofChildIndex: Nat): ?(K, V) {
    let predecessorIndex: Nat = ofChildIndex - 1;
    borrowFromLeafChild(children, predecessorIndex, #predecessor)
  };

  // attempts to retrieve the in max key of the child leaf node directly to the right if the node will allow it
  // returns the deleted max key if able to retrieve, null if not able
  //
  // mutates the predecessing node's keys
  public func borrowFromRightLeafChild<K, V>(children: [var ?Types.Node<K, V>], ofChildIndex: Nat): ?(K, V) {
    borrowFromLeafChild(children, ofChildIndex + 1, #successor)
  };

  func borrowFromLeafChild<K, V>(children: [var ?Types.Node<K, V>], borrowChildIndex: Nat, childSide: InorderBorrowType): ?(K, V) {
    let minKeys = minKeysFromOrder(children.size());

    switch(children[borrowChildIndex]) {
      case (?#leaf({ data; })) {
        if (data.count > minKeys) {
          // able to borrow a key-value from this child, so decrement the count of kvs
          data.count -= 1; // Since enforce order >= 4, there will always be at least 1 element per node
          switch(childSide) {
            case (#predecessor) { 
              let deletedKV = data.kvs[data.count];
              data.kvs[data.count] := null;
              deletedKV;
            };
            case (#successor) { ?AU.deleteAndShiftValuesOver(data.kvs, 0); };
          }
        } else { null }
      };
      case _ { Debug.trap("UNREACHABLE_ERROR: file a bug report! In borrowFromLeafChild, the node at the borrow child index cannot be null or internal") }
    }
  };


  type InternalBorrowResult<K, V> = {
    #borrowed: InternalBorrow<K, V>;
    #notEnoughKeys: Types.Internal<K, V>
  };
  
  type InternalBorrow<K, V> = {
    deletedSiblingKVPair: ?(K, V);
    child: ?Types.Node<K, V>;
  };

  // Attempts to borrow a KV and child from an internal sibling node
  public func borrowFromInternalSibling<K, V>(children: [var ?Types.Node<K, V>], borrowChildIndex: Nat, borrowType: InorderBorrowType): InternalBorrowResult<K, V> {
    let minKeys = minKeysFromOrder(children.size());

    switch(children[borrowChildIndex]) {
      case (?#internal({ data; children })) {
        if (data.count > minKeys) {
          data.count -= 1;
          switch(borrowType) {
            case (#predecessor) { 
              let deletedSiblingKVPair = data.kvs[data.count];
              data.kvs[data.count] := null;
              let child = children[data.count + 1];
              children[data.count + 1] := null;
              #borrowed({
                deletedSiblingKVPair; 
                child;
              })
            };
            case (#successor) { 
              #borrowed({
                deletedSiblingKVPair = ?AU.deleteAndShiftValuesOver(data.kvs, 0); 
                child = ?AU.deleteAndShiftValuesOver(children, 0);
              });
            };
          }
        } else { #notEnoughKeys({ data; children }) }
      };
      case _ { Debug.trap("UNREACHABLE_ERROR: file a bug report! In borrow from internal sibling, the child at the borrow index cannot be null or a leaf") }
    }
  };

  type SiblingSide = { #left; #right };

  // Rotates the borrowed KV and child from sibling side of the internal node to the internal child recipient
  public func rotateBorrowedKVsAndChildFromSibling<K, V>(
    internalNode: Types.Internal<K, V>,
    parentRotateIndex: Nat,
    borrowedSiblingKVPair: ?(K, V),
    borrowedSiblingChild: ?Types.Node<K, V>,
    internalChildRecipient: Types.Internal<K, V>,
    siblingSide: SiblingSide
  ) {
    // if borrowing from the left, the rotated key and child will always be inserted first 
    // if borrowing from the right, the rotated key and child will always be inserted last 
    let (kvIndex, childIndex) = switch(siblingSide) {
      case (#left) { (0, 0) };
      case (#right) { (internalChildRecipient.data.count, internalChildRecipient.data.count + 1) };
    };

    // get the parent kv that will be pushed down the the child
    let kvPairToBePushedToChild = internalNode.data.kvs[parentRotateIndex];
    // replace the parent with the sibling kv
    internalNode.data.kvs[parentRotateIndex] := borrowedSiblingKVPair;
    // push the kv and child down into the internalChild
    insertAtIndexOfNonFullNodeData<K, V>(internalChildRecipient.data, kvPairToBePushedToChild, kvIndex);

    AU.insertAtPosition<Types.Node<K, V>>(internalChildRecipient.children, borrowedSiblingChild, childIndex, internalChildRecipient.data.count);
  };


  // Merges the kvs and children of two internal nodes, pushing the parent kv in between the right and left halves 
  public func mergeChildrenAndPushDownParent<K, V>(leftChild: Types.Internal<K, V>, parentKV: ?(K, V), rightChild: Types.Internal<K, V>): Types.Internal<K, V> {
    {
      data = mergeData<K, V>(leftChild.data, parentKV, rightChild.data);
      children = mergeChildren(leftChild.children, rightChild.children);
    }
  };
  

  func mergeData<K, V>(leftData: Types.Data<K, V>, parentKV: ?(K, V), rightData: Types.Data<K, V>): Types.Data<K, V> {
    assert leftData.count <= minKeysFromOrder(leftData.kvs.size() + 1);
    assert rightData.count <= minKeysFromOrder(rightData.kvs.size() + 1);

    let mergedKVs = Array.init<?(K, V)>(leftData.kvs.size(), null);
    var i = 0;
    while (i < leftData.count) {
      mergedKVs[i] := leftData.kvs[i];
      i += 1;
    };

    mergedKVs[i] := parentKV;
    i += 1;

    var j = 0;
    while (j < rightData.count) {
      mergedKVs[i] := rightData.kvs[j];
      i += 1;
      j += 1;
    };

    {
      kvs = mergedKVs;
      var count = leftData.count + 1 + rightData.count;
    }
  };


  func mergeChildren<K, V>(leftChildren: [var ?Types.Node<K, V>], rightChildren: [var ?Types.Node<K, V>]): [var ?Types.Node<K, V>] {
    let mergedChildren = Array.init<?Types.Node<K, V>>(leftChildren.size(), null);
    var i = 0;

    while (Option.isSome(leftChildren[i])) {
      mergedChildren[i] := leftChildren[i];
      i += 1;
    };

    var j = 0;
    while (Option.isSome(rightChildren[j])) {
      mergedChildren[i] := rightChildren[j];
      i += 1;
      j += 1;
    };

    mergedChildren;
  };


}