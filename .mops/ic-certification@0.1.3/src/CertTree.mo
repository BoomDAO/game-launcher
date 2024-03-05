/// **Imperative wrapper of MerkleTree**
///
/// This module contains an imperative wrapper of the functional API provided by `MerkleTree`.
/// This makes common usage pattern around these trees more convenient.
///
/// This module defines two types: 
///
/// * The `Store`. This is meant to be your canister's single hash tree. It is separated
///   from the class providing functions so that it can be put in stable memory:
///
/// * The `Ops` class. This wraps such a `Store` and offers all the operations you expect.
///
/// So this is the suggested idiom:
///
///   ```
///   stable let cert_store : CertTree.Store = CertTree.newStore();
///   let ct = CertTree.Ops(cert_store);
///   ```

import MerkleTree "MerkleTree";
import Iter "mo:base/Iter";
import CertifiedData "mo:base/CertifiedData";

module {

    public type Store = { var tree : MerkleTree.Tree };

    public type Path = MerkleTree.Path;
    public type Value = MerkleTree.Value;
    public type Key = MerkleTree.Key;
    public type Hash = MerkleTree.Hash;
    public type Witness = MerkleTree.Witness;


    public func newStore() : Store {
      return { var tree = MerkleTree.empty() }
    };

    public class Ops(ct : Store) {
        /// Inserting a value at a given path into the tree.
        ///
        /// An existing value (or subtree) under that path is overridden.
        ///
        /// If there are values at any prefix of the given path,
        /// they will be removed.
        public func put(ks : Path, v : Value) {
            ct.tree := MerkleTree.put(ct.tree, ks, v);
        };
        
        /// Deleting a path from a tree.
        ///
        /// This removes the given path from the tree, independently
        /// of whether there is a value at that path, or a whole subtree.
        ///
        /// If there are values at any prefix of the given path,
        /// they will be removed.
        public func delete(ks : Path) {
            ct.tree := MerkleTree.delete(ct.tree, ks);
        };

        /// Looking up a value at a path
        ///
        /// This will return `null` if the path does not exist, or if 
        /// there is a subtree (and not a value) at that key. 
        public func lookup(ks : Path) : ?Value {
            MerkleTree.lookup(ct.tree, ks);
        };

        /// Lookup up all labels at a path.
        ///
        /// Returns an iterator, so you can use it with
        /// ```
        /// for (k in ct.labelsAt(["some", "path"))) { … }
        /// ```
        public func labelsAt(ks : Path) : Iter.Iter<Key> {
            MerkleTree.labelsAt(ct.tree, ks)
        };

        /// Root hash
        public func treeHash() : Hash {
            MerkleTree.treeHash(ct.tree);
        };

        /// Sets the canister's certified data to the root hash
        /// Call this at the end of any update function that changed the certified data tree
        public func setCertifiedData() {
            CertifiedData.set(treeHash());
        };

        /// Create a witness that reveals the value of the key `k` in the tree `tree`.
        ///
        /// If `k` is not in the tree, the witness will prove that fact.
        public func reveal(path : Path) : Witness {
            MerkleTree.reveal(ct.tree, path)
        };

        /// Reveals multiple paths
        public func reveals(paths : Iter.Iter<Path>) : Witness {
            MerkleTree.reveals(ct.tree, paths)
        };

        /// Encodes a witness as CBOR, e.g. for certified assets
        public func encodeWitness(w : Witness) : Blob {
            MerkleTree.encodeWitness(w);
        }
    };
};

