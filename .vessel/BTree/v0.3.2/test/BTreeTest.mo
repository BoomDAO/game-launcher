import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import BT "../src/BTree";
import BTM "./BTreeMatchers";

func testableNatBTree(t: BT.BTree<Nat, Nat>): T.TestableItem<BT.BTree<Nat, Nat>> {
  BTM.testableBTree(t, Nat.equal, Nat.equal, Nat.toText, Nat.toText)
};  

// Concise helper for setting up a BTree of type BTree<Nat, Nat> with multiple elements
func quickCreateBTreeWithKVPairs(order: Nat, keyValueDup: [Nat]): BT.BTree<Nat, Nat> {
  let kvPairs = Array.map<Nat, (Nat, Nat)>(keyValueDup, func(k) { (k, k) });

  BT.fromArray<Nat, Nat>(order, Nat.compare, kvPairs);
};

func quickCreateNatResultSet(start: Nat, end: Nat): [(Nat, Nat)] {
  Array.tabulate<(Nat, Nat)>(end - start + 1, func(i) {
    let el = i + start;
    (el, el)
  });
};

func quickCreateNatResultSetReverse(end: Nat, start: Nat): [(Nat, Nat)] {
  assert end >= start and end > 0;
  Array.tabulate<(Nat, Nat)>(end - start + 1, func(i) {
    let el = end - i: Nat;
    (el, el)
  });
};


let initSuite = S.suite("init", [
  S.test("initializes an empty BTree with order 4 to have the correct number of keys (order - 1)",
    BT.init<Nat, Nat>(?4),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null, null];
          var count = 0;
        }
      });
      var size = 0;
      order = 4;
    }))
  ),
  S.test("if null order is provided, initializes an empty BTree with order 32 to have the correct number of keys (order - 1)",
    BT.init<Nat, Nat>(null),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null];
          var count = 0;
        }
      });
      var size = 0;
      order = 32;
    }))
  ),
  /* Comment out to test that these tests trap on BTree initialization
  S.test("if the order provided is less than 4, traps",
    BT.init<Nat, Nat>(?3),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null];
          var count = 0;
        }
      });
      var size = 0;
      order = 3;
    }))
  ),
  S.test("if the order provided is greater than 512, traps",
    BT.init<Nat, Nat>(?513),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null];
          var count = 0;
        }
      });
      var size = 0;
      order = 512;
    }))
  )
  */
]);

let getSuite = S.suite("get", [
  S.test("returns null on an empty BTree",
    BT.get<Nat, Nat>(BT.init<Nat, Nat>(?4), Nat.compare, 5),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns null on a BTree leaf node that does not contain the key",
    BT.get<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [3, 7]), Nat.compare, 5),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns null on a multi-level BTree that does not contain the key",
    BT.get<Nat, Nat>(
      quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]),
      Nat.compare,
      21
    ),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns null on a multi-level BTree that does not contain the key, if the key is greater than all elements in the tree",
    BT.get<Nat, Nat>(
      quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]),
      Nat.compare,
      200
    ),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns the value if a BTree leaf node contains the key",
    BT.get<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [3, 7, 10]), Nat.compare, 10),
    M.equals(T.optional<Nat>(T.natTestable, ?10))
  ),
  S.test("returns the value if a BTree internal node contains the key",
    BT.get<Nat, Nat>(
      quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]),
      Nat.compare,
      120
    ),
    M.equals(T.optional<Nat>(T.natTestable, ?120))
  ),
]);

func incrementNatFunction(nat: ?Nat): Nat {
  switch(nat) {
    case null { 0 };
    case (?n) { n + 1 };
  }
};

let updateSuite = S.suite("update", [
  S.suite("root as leaf tests", [
    S.test("inserts, applying the function correctly into an empty BTree",
      do {
        let t = BT.init<Nat, Nat>(?4);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 4, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(4, 0), null, null];
            var count = 1;
          }
        });
        var size = 1;
        order = 4;
      }))
    ),
    S.test("updating an element into a BTree that does not exist returns null",
      do {
        let t = BT.init<Nat, Nat>(?4);
        BT.update<Nat, Nat>(t, Nat.compare, 4, incrementNatFunction);
      },
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.test("updates an already existing element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 2, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 3), ?(4, 4), ?(6, 6), null, null];
            var count = 3;
          }
        });
        var size = 3;
        order = 6;
      }))
    ),
    S.test("returns the previous value of when updating an already existing element in the BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        BT.update<Nat, Nat>(t, Nat.compare, 2, incrementNatFunction);
      },
      M.equals(T.optional<Nat>(T.natTestable, ?2))
    ),
    S.test("update inserts a new smallest element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 1, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(1, 0), ?(2, 2), ?(4, 4), ?(6, 6), null];
            var count = 4;
          }
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("update inserts middle element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 5, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(5, 0), ?(6, 6), null];
            var count = 4;
          }
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("update inserts last element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 8, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(6, 6), ?(8, 0), null];
            var count = 4;
          }
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("update that is inserting greatest element into full leaf splits an even ordererd BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 8, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 0), null, null];
                var count = 1;
              };
            }),
            null,
            null
          ]
        });
        var size = 4;
        order = 4;
      }))
    ),
    S.test("update that is inserting greatest element into full leaf splits an odd ordererd BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(5, [2, 4, 6, 7]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 8, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null, null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 0), null, null];
                var count = 2;
              };
            }),
            null,
            null,
            null
          ]
        });
        var size = 5;
        order = 5;
      }))
    ),
  ]),
  S.suite("root as internal tests", [
    S.test("updating an element that already exists applies the function to replace it correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 8, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 9), null, null];
                var count = 1;
              };
            }),
            null,
            null,
          ]
        });
        var size = 4;
        order = 4;
      }))
    ),
    S.test("update inserts an element that does not yet exist into the right child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 7, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 0), ?(8, 8), null];
                var count = 2;
              };
            }),
            null,
            null,
          ]
        });
        var size = 5;
        order = 4;
      }))
    ),
    S.test("update inserts an element that does not yet exist into the left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 3, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(3, 0), ?(4, 4)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
            null,
          ]
        });
        var size = 5;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not yet exist into a full left most child promotes to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 1, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), null];
            var count = 2;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 0), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
          ]
        });
        var size = 6;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not yet exist into a full right most child promotes it to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 12, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), ?(12, 0)];
            var count = 3;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), ?(10, 10), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
            }),
          ]
        });
        var size = 9;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not yet exist into a full right most child promotes it to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15, 12]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 7, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), ?(12, 12)];
            var count = 3;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 0), ?(8, 8), ?(10, 10)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
            }),
          ]
        });
        var size = 10;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not exist into a tree with a full root that where the inserted element is promoted to become the new root, also hitting case 2 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15, 12, 7]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 9, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(9, 0), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), ?(6, 6), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), ?(8, 8), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(12, 12), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null
          ]
        });
        var size = 11;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not exist into a tree with a full root that where the inserted element is promoted to be in the left internal child of the new root",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 10, 20, 8, 5, 7, 15, 25, 40, 3]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 4, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(10, 10), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(4, 0), ?(7, 7), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(8, 8), null, null];
                    var count = 1;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(25, 25), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), ?(20, 20), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(40, 40), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null
          ]
        });
        var size = 11;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not exist into that promotes and element from a full internal into a root internal with space, hitting case 2 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 10, 20, 8, 5, 7, 15, 25, 40, 3, 4, 50, 60, 70, 80, 90, 100, 110, 120]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 130, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(10, 10), ?(90, 90), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(4, 4), ?(7, 7), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(8, 8), null, null];
                    var count = 1;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(25, 25), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), ?(20, 20), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(40, 40), ?(50, 50), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(70, 70), ?(80, 80), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(120, 120), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(100, 100), ?(110, 110), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(130, 0), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ];
            }),
            null
          ]
        });
        var size = 20;
        order = 4;
      }))
    ),
    S.test("an update that inserts an element that does not exist into a tree with a full root, promoting an element to the root and hitting case 1 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [25, 100, 50, 75, 125, 150, 175, 200, 225, 250, 5]);
        let _ = BT.update<Nat, Nat>(t, Nat.compare, 10, incrementNatFunction);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(150, 150), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(25, 25), ?(75, 75), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), ?(10, 0), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(50, 50), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(100, 100), ?(125, 125), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(225, 225), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(175, 175), ?(200, 200), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(250, 250), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null
          ]
        });
        var size = 12;
        order = 4;
      }))
    ),
  ])
]);

let insertSuite = S.suite("insert", [
  S.suite("root as leaf tests", [
    S.test("inserts into an empty BTree",
      do {
        let t = BT.init<Nat, Nat>(?4);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 4, 4);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(4, 4), null, null];
            var count = 1;
          }
        });
        var size = 1;
        order = 4;
      }))
    ),
    S.test("inserting an element into a BTree that does not exist returns null",
      do {
        let t = BT.init<Nat, Nat>(?4);
        BT.insert<Nat, Nat>(t, Nat.compare, 4, 4);
      },
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.test("replaces already existing element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 2, 22);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 22), ?(4, 4), ?(6, 6), null, null];
            var count = 3;
          }
        });
        var size = 3;
        order = 6;
      }))
    ),
    S.test("returns the previous value of when replacing an already existing element in the BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        BT.insert<Nat, Nat>(t, Nat.compare, 2, 22);
      },
      M.equals(T.optional<Nat>(T.natTestable, ?2))
    ),
    S.test("inserts new smallest element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 1, 1);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(1, 1), ?(2, 2), ?(4, 4), ?(6, 6), null];
            var count = 4;
          }
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("inserts middle element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 5, 5);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(5,5), ?(6, 6), null];
            var count = 4;
          }
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("inserts last element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(6, 6), ?(8, 8), null];
            var count = 4;
          }
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("orders multiple inserts into a BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [8, 2, 10, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(6, 6), ?(8, 8), ?(10, 10)];
            var count = 5;
          }
        });
        var size = 5;
        order = 6;
      }))
    ),
    S.test("inserting greatest element into full leaf splits an even ordererd BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
            null
          ]
        });
        var size = 4;
        order = 4;
      }))
    ),
    S.test("inserting greatest element into full leaf splits an odd ordererd BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(5, [2, 4, 6, 7]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null, null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), null, null];
                var count = 2;
              };
            }),
            null,
            null,
            null
          ]
        });
        var size = 5;
        order = 5;
      }))
    ),
  ]),
  S.suite("root as internal tests", [
    S.test("inserting an element that already exists replaces it",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 88);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 88), null, null];
                var count = 1;
              };
            }),
            null,
            null,
          ]
        });
        var size = 4;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into the right child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 7, 7);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), null];
                var count = 2;
              };
            }),
            null,
            null,
          ]
        });
        var size = 5;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into the left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 3, 3);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(3, 3), ?(4, 4)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
            null,
          ]
        });
        var size = 5;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into a full left most child promotes to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 1, 1);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), null];
            var count = 2;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
          ]
        });
        var size = 6;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into a full right most child promotes it to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 12, 12);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), ?(12, 12)];
            var count = 3;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), ?(10, 10), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
            }),
          ]
        });
        var size = 9;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into a full right most child promotes it to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15, 12]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 7, 7);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), ?(12, 12)];
            var count = 3;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), ?(10, 10)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
            }),
          ]
        });
        var size = 10;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into a tree with a full root that where the inserted element is promoted to become the new root, also hitting case 2 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15, 12, 7]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 9, 9);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(9, 9), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), ?(6, 6), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), ?(8, 8), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(12, 12), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null

          ]
        });
        var size = 11;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into a tree with a full root that where the inserted element is promoted to be in the left internal child of the new root",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 10, 20, 8, 5, 7, 15, 25, 40, 3]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 4, 4);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(10, 10), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(4, 4), ?(7, 7), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(8, 8), null, null];
                    var count = 1;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(25, 25), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), ?(20, 20), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(40, 40), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null

          ]
        });
        var size = 11;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into that promotes an element from a full internal into a root internal with space, hitting case 2 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 10, 20, 8, 5, 7, 15, 25, 40, 3, 4, 50, 60, 70, 80, 90, 100, 110, 120]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 130, 130);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(10, 10), ?(90, 90), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(4, 4), ?(7, 7), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(8, 8), null, null];
                    var count = 1;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(25, 25), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), ?(20, 20), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(40, 40), ?(50, 50), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(70, 70), ?(80, 80), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(120, 120), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(100, 100), ?(110, 110), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(130, 130), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ];
            }),
            null

          ]
        });
        var size = 20;
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into a tree with a full root, promoting an element to the root and hitting case 1 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [25, 100, 50, 75, 125, 150, 175, 200, 225, 250, 5]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 10, 10);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(150, 150), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(25, 25), ?(75, 75), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), ?(10, 10), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(50, 50), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(100, 100), ?(125, 125), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(225, 225), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(175, 175), ?(200, 200), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(250, 250), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null

          ]
        });
        var size = 12;
        order = 4;
      }))
    ),
  ])
]);

let substituteKeySuite = S.suite("substituteKey", [
  S.suite("root as leaf tests", [
    S.test("if the key does not exist, does nothing",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [3, 7, 10]);
        let _ = BT.substituteKey<Nat, Nat>(t, Nat.compare, 11, 13);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(3, 3), ?(7, 7), ?(10, 10)];
            var count = 3;
          }
        });
        var size = 3;
        order = 4;
      }))
    ),
    S.test("substitutes the key in a BTree leaf node",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [3, 7, 10]);
        let v = BT.substituteKey<Nat, Nat>(t, Nat.compare, 10, 11);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(3, 3), ?(7, 7), ?(11, 10)];
            var count = 3;
          }
        });
        var size = 3;
        order = 4;
      }))
    ),
    S.test("substitutes the key in a BTree leaf node, if the key is less than all elements in the tree",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [3, 7, 10]);
        let _ = BT.substituteKey<Nat, Nat>(t, Nat.compare, 3, 1);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(1, 3), ?(7, 7), ?(10, 10)];
            var count = 3;
          }
        });
        var size = 3;
        order = 4;
      }))
    ),
  ]),
  S.suite("root as internal tests with order 4", [
    S.test("if the key does not exist, does nothing",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [5, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250]);
        let _ = BT.substituteKey<Nat, Nat>(t, Nat.compare, 80, 80);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(50, 50), ?(125, 125), ?(200, 200)];
            var count = 3;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(5, 5), ?(25, 25), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(75, 75), ?(100, 100), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(150, 150), ?(175, 175), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(225, 225), ?(250, 250), null];
                var count = 2;
              };
            })
          ];
        });
        var size = 11;
        order = 4;
      }))
    ),
    S.test(
      "substitutes the key in a BTree internal node, swapping it's position in the tree",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [5, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250]);
        let _ = BT.substituteKey<Nat, Nat>(t, Nat.compare, 200, 80);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(50, 50), ?(125, 125), ?(175, 175)];
            var count = 3;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(5, 5), ?(25, 25), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(75, 75), ?(80, 200), ?(100, 100)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(150, 150), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(225, 225), ?(250, 250), null];
                var count = 2;
              };
            })
          ];
        });
        var size = 11;
        order = 4;
      }))
    ),
    S.test(
      "substitutes the key in a BTree internal node, swapping it's position in the tree, if the key is less than all elements in the tree",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [5, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250]);
        let _ = BT.substituteKey<Nat, Nat>(t, Nat.compare, 5, 300);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(50, 50), ?(125, 125), ?(200, 200)];
            var count = 3;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(25, 25), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(75, 75), ?(100, 100), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(150, 150), ?(175, 175), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(225, 225), ?(250, 250), ?(300, 5)];
                var count = 3;
              };
            })
          ];
        });
        var size = 11;
        order = 4;
      }))
    ),
  ])
]);

let deleteSuite = S.suite("delete", [
  S.suite("deletion from a BTree with root as leaf (tree height = 1)", [
    S.test("if tree is empty returns null",
      BT.delete<Nat, Nat>(BT.init<Nat, Nat>(?4), Nat.compare, 5),
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.test("if the key exists in the BTree returns that key",
      BT.delete<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [2, 7]), Nat.compare, 2),
      M.equals(T.optional<Nat>(T.natTestable, ?2))
    ),
    S.test("if the key exists in the BTree removes the kv from the leaf correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 7, 10]);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(7, 7), ?(10, 10), null];
            var count = 2;
          }
        });
        var size = 2;
        order = 4;
      }))
    ),
  ]),
  S.suite("deletion from leaf node", [
    S.test("if the key does not exist returns null",
      BT.delete<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40]), Nat.compare, 5),
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.suite("if the key exists", [
      S.test("if the leaf has more than the minimum # of keys, deletes the key correctly",
        do {
          let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40]);
          ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
          t
        },
        M.equals(testableNatBTree({
          var root = #internal({
            data = {
              kvs = [var ?(30, 30), null, null];
              var count = 1;
            };
            children = [var
              ?#leaf({
                data = { 
                  kvs = [var ?(20, 20), null, null];
                  var count = 1;
                }
              }),
              ?#leaf({
                data = { 
                  kvs = [var ?(40, 40), null, null];
                  var count = 1;
                }
              }),
              null,
              null
            ]
          });
          var size = 3;
          order = 4;
        }))
      ),
      S.suite("if the leaf has the minimum # of keys", [
        S.test("if the leaf is rightmost and can borrow from its left sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(20, 20), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            });
            var size = 3;
            order = 4;
          }))
        ),
        S.test("if the leaf is leftmost and can borrow from its left sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(40, 40), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(50, 50), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(70, 70), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            });
            var size = 5;
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can borrow from its left sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(20, 20), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(70, 70), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            });
            var size = 5;
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling but can borrow from its right sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(30, 30), ?(70, 70), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(60, 60), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(80, 80), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            });
            var size = 5;
            order = 4;
          }))
        ),
        S.test("if the leaf is on the left and can't borrow from its left sibling or its right sibling, but can merge with the parent and internal has > minKeys deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(70, 70), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), ?(60, 60), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(80, 80), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            });
            var size = 4;
            order = 4;
          }))
        ),
        S.test("if the leaf is the left most and can't borrow from its right sibling, but can merge with the parent and internal has > minKeys returns the deleted value",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            BT.delete<Nat, Nat>(t, Nat.compare, 10);
          },
          M.equals(T.optional<Nat>(T.natTestable, ?10))
        ),
        S.test("if the leaf is left most and can't borrow from its left sibling, but can merge with the parent and internal has <= minKeys merges the leaf with its right sibling and parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 72, 75]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(90, 90), null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(60, 60), ?(75, 75), null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(30, 30), ?(50, 50), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(70, 70), ?(72, 72), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(80, 80), null, null];
                        var count = 1;
                      };
                    }),
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(120, 120), null, null];
                    var count = 1;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(100, 100), ?(110, 110), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(130, 130), null, null];
                        var count = 1;
                      };
                    }),
                    null,
                    null
                  ]
                }),
                null,
                null
              ]
            });
            var size = 12;
            order = 4;
          }))
        ),
        S.test("if the leaf is right most and can't borrow from its left sibling, but can merge with the parent and internal has > minKeys deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 80);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(30, 30), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(60, 60), ?(70, 70), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            });
            var size = 4;
            order = 4;
          }))
        ),
        S.test("if the leaf is right most and can't borrow from its left sibling, but can merge with the parent and internal has <= minKeys merges the leaf with its left sibling and parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 72, 75]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 72);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 80);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(90, 90), null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(30, 30), ?(60, 60), null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(10, 10), ?(20, 20), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(40, 40), ?(50, 50), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(70, 70), ?(75, 75), null];
                        var count = 2;
                      };
                    }),
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(120, 120), null, null];
                    var count = 1;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(100, 100), ?(110, 110), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(130, 130), null, null];
                        var count = 1;
                      };
                    }),
                    null,
                    null
                  ]
                }),
                null,
                null
              ]
            });
            var size = 13;
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling or its right sibling, but can merge with the parent and internal has > minKeys deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 60);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(70, 70), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), ?(30, 30), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(80, 80), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            });
            var size = 4;
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and root is the parent internal and parent has <= minKeys flattens the tree and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 60);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 30);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 80);
            t
          },
          M.equals(testableNatBTree({
            var root = #leaf({
              data = {
                kvs = [var ?(10, 10), ?(70, 70), null];
                var count = 2;
              };
            });
            var size = 2;
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and the parent internal has <= minKeys merges the leaf with its left sibling and the parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 72, 75]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 72);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 70);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(90, 90), null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(30, 30), ?(75, 75), null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(10, 10), ?(20, 20), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(40, 40), ?(60, 60), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(80, 80), null, null];
                        var count = 1;
                      };
                    }),
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(120, 120), null, null];
                    var count = 1;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(100, 100), ?(110, 110), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(130, 130), null, null];
                        var count = 1;
                      };
                    }),
                    null,
                    null
                  ]
                }),
                null,
                null
              ]
            });
            var size = 12;
            order = 4;
          }))
        ),
        S.test("BTree with order=6 test of if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and the parent internal has > minKeys merges the leaf with its left sibling and the parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(6, Array.tabulate<Nat>(26, func(i) { i+1 }));
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 14);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(16, 16), null, null, null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(4, 4), ?(12, 12), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(1, 1), ?(2, 2), ?(3, 3), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(5, 5), ?(6, 6), ?(7, 7), ?(8, 8), null];
                        var count = 4;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(13, 13), ?(15, 15), null, null, null];
                        var count = 2;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(20, 20), ?(24, 24), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(17, 17), ?(18, 18), ?(19, 19), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(21, 21), ?(22, 22), ?(23, 23), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(25, 25), ?(26, 26), null, null, null];
                        var count = 2;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                null,
                null,
                null,
                null
              ]
            });
            var size = 22;
            order = 6;
          }))
        ),
        S.test("BTree with order=6 test of if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and the parent internal has <= minKeys so pulls from its left sibling through the parent (root) key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(6, Array.tabulate<Nat>(26, func(i) { i+1 }));
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 23);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 26);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(12, 12), null, null, null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(4, 4), ?(8, 8), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(1, 1), ?(2, 2), ?(3, 3), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(5, 5), ?(6, 6), ?(7, 7), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(9, 9), ?(10, 10), ?(11, 11), null, null];
                        var count = 3;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(16, 16), ?(20, 20), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(13, 13), ?(14, 14), ?(15, 15), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(17, 17), ?(18, 18), ?(19, 19), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(21, 21), ?(22, 22), ?(24, 24), ?(25, 25), null];
                        var count = 4;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                null,
                null,
                null,
                null
              ]
            });
            var size = 24;
            order = 6;
          }))
        ),
      ]),
    ])
  ]),
  S.suite("deletion from internal node", [
    S.test("Simple case deleting root borrows predecessor from left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [1,2,3,4]);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(2, 2), null, null];
            var count = 1;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              }
            }),
            null,
            null
          ]
        });
        var size = 3;
        order = 4;
      }))
    ),
    S.test("Simple case deleting root borrows inorder predecessor but then needs to rebalance via left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(8, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), null];
            var count = 2;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(3, 3), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), null];
                var count = 2;
              }
            }),
            null
          ]
        });
        var size = 6;
        order = 4;
      }))
    ),
    S.test("Simple case deleting root borrows inorder predecessor but then needs to rebalance via right child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(8, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(7, 7), null];
            var count = 2;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              }
            }),
            null
          ]
        });
        var size = 5;
        order = 4;
      }))
    ),
    S.test("Order 6, simple case deleting root with minimum number of keys condenses the BTree into a leaf",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [1,2,3,4,5,6]);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
        t
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(1, 1), ?(2, 2), ?(5, 5), ?(6, 6), null];
            var count = 4;
          };
        });
        var size = 4;
        order = 6;
      }))
    ),
    S.test("BTree with height 3 root borrows inorder predecessor and no need to rebalance",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(8, 8), ?(18, 18), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), ?(6, 6), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), ?(5, 5), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(12, 12), ?(15, 15), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), ?(11, 11), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(13, 13), ?(14, 14), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(16, 16), ?(17, 17), null];
                    var count = 2;
                  }
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(21, 21), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(19, 19), ?(20, 20), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(22, 22), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            }),
            null
          ]
        });
        var size = 21;
        order = 4;
      }))
    ),
    S.test("BTree with height 3 root replaces with inorder predecessor and borrows from left child to rotate left",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 12);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 13);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 14);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 16);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 18);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), ?(17, 17), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), ?(5, 5), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(9, 9), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), ?(8, 8), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), ?(15, 15), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(21, 21), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(19, 19), ?(20, 20), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(22, 22), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            }),
            null
          ]
        });
        var size = 16;
        order = 4;
      }))
    ),
    S.test("BTree with height 3 root replaces with inorder predecessor and cannot borrow from left so borrows from right child to rotate right",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 1);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 7);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(12, 12), ?(18, 18), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), ?(11, 11), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(13, 13), ?(14, 14), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(16, 16), ?(17, 17), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(21, 21), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(19, 19), ?(20, 20), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(22, 22), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            }),
            null
          ]
        });
        var size = 16;
        order = 4;
      }))
    ),
    S.test("BTree with height 3 root replaces with inorder predecessor and cannot borrow from left or right so shrinks the tree size",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 7);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(8, 8), ?(12, 12), null];
            var count = 2;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(3, 3), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(10, 10), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(13, 13), null, null];
                var count = 1;
              };
            }),
            null
          ]
        });
        var size = 6;
        order = 4;
      }))
    ),
    S.test("BTree with order=6 and height 3 root replaces with inorder predecessor and cannot borrow from left or right so shrinks the tree size",
      do {
        let t = quickCreateBTreeWithKVPairs(6, Array.tabulate<Nat>(26, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 7);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 8);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 13);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 16);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(4, 4), ?(15, 15), ?(20, 20), ?(24, 24), null];
            var count = 4;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null, null, null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(5, 5), ?(11, 11), ?(12, 12), ?(14, 14), null];
                var count = 4;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(17, 17), ?(18, 18), ?(19, 19), null, null];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(21, 21), ?(22, 22), ?(23, 23), null, null];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(25, 25), ?(26, 26), null, null, null];
                var count = 2;
              };
            }),
            null,
          ]
        });
        var size = 18;
        order = 6;
      }))
    ),
  ]),
]);

let scanLimitSuite = S.suite("scanLimit", [
  S.suite("iterating foward", [
    S.test("if limit is 0 returns the empty response",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
        BT.scanLimit(
          t,
          Nat.compare,
          0,
          4,
          #fwd,
          0,
        )
      },
      M.equals(BTM.testableNatBTreeScanLimitResult({
        results = [];
        nextKey = null;
      }))
    ),
    S.test("if the lower bound is greater than the upper bound returns the empty response",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
        BT.scanLimit(
          t,
          Nat.compare,
          4,
          0,
          #fwd,
          5,
        )
      },
      M.equals(BTM.testableNatBTreeScanLimitResult({
        results = [];
        nextKey = null;
      }))
    ),
    S.suite("with BTree as leaf", [
      S.test("if the lower bound is greater than the greatest key in the tree returns the empty response",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            4,
            7,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and bounds exactly contain all elements",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            1,
            3,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(1, 1), (2, 2), (3, 3)];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and lower bound equals upper bound",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            2,
            2,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(2, 2)];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and bounds are from first to middle element",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            0,
            2,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(1, 1), (2, 2)];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and bounds are from middle to last element",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            2,
            4,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(2, 2), (3, 3)];
          nextKey = null;
        }))
      ),
      S.test("if limit is less than the result set",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            0,
            4,
            #fwd,
            2,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(1, 1), (2, 2)];
          nextKey = ?3;
        }))
      ),
      S.test("if there are gaps in the contents of the BTree (i.e. every other number) and the limit is less than the result set",
        do {
          let t = quickCreateBTreeWithKVPairs(8, Array.tabulate<Nat>(4, func(i) { i*2+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            2,
            8,
            #fwd,
            2,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(3, 3), (5, 5)];
          nextKey = ?7;
        }))
      ),
    ]),
    S.suite("with BTree as multiple levels", [
      S.test("if lower bound is greater than the greatest key returns empty response",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            40,
            50,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [];
          nextKey = null;
        }))
      ),
      S.test("if upper bound is lower than the lower key returns empty response",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+10 }));
          BT.scanLimit(
            t,
            Nat.compare,
            1,
            9,
            #fwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [];
          nextKey = null;
        }))
      ),
      S.suite("if the limit is greater than the result set", [
        S.test("if bounds contain all elements",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 31);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to a middle leaf element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              7,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 7);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to a end leaf element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              17,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 17);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to an internal kv",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              21,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 21);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(4, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              0,
              4,
              #fwd,
              2,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(1, 1), (3, 3)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a 3-level root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              10,
              16,
              #fwd,
              3,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(11, 11), (13, 13), (15, 15)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a first non-root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              14,
              22,
              #fwd,
              4,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(15, 15), (17, 17), (19, 19), (21, 21)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a last non-root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              2,
              10,
              #fwd,
              4,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(3, 3), (5, 5), (7, 7), (9, 9)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to an root internal kv",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              9,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 9);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to an root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(4, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              0,
              6,
              #fwd,
              3,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(1, 1), (3, 3), (5, 5)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a middle leaf element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              10,
              31,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(10, 31);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a last leaf element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              23,
              31,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(23, 31);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a middle internal element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              6,
              31,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(6, 31);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a root internal element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              18,
              31,
              #fwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(18, 31);
            nextKey = null;
          }))
        ),
      ]),
      S.suite("if the limit is less than the result set", [
        S.test("if bounds contain all elements and stop on a leaf kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              7,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 7);
            nextKey = ?8;
          }))
        ),
        S.test("if bounds contain all elements and stop on a leaf kv with next key being a internal key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              11,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 11);
            nextKey = ?12;
          }))
        ),
        S.test("if bounds contain all elements and stop on a leaf kv with next key being a root key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              17,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 17);
            nextKey = ?18;
          }))
        ),
        S.test("if bounds contain all elements and stop on an internal kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              12,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 12);
            nextKey = ?13;
          }))
        ),
        S.test("if bounds contain all elements and stop on an end internal kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              30,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 30);
            nextKey = ?31;
          }))
        ),
        S.test("if bounds contain all elements and stop on an root kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #fwd,
              18,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSet(1, 18);
            nextKey = ?19;
          }))
        ),
      ]),
    ]),
  ]),
  S.suite("iterating backwards", [
    S.test("if limit is 0 returns the empty response",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
        BT.scanLimit(
          t,
          Nat.compare,
          0,
          4,
          #bwd,
          0,
        )
      },
      M.equals(BTM.testableNatBTreeScanLimitResult({
        results = [];
        nextKey = null;
      }))
    ),
    S.test("if the lower bound is greater than the upper bound returns the empty response",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
        BT.scanLimit(
          t,
          Nat.compare,
          4,
          0,
          #bwd,
          5,
        )
      },
      M.equals(BTM.testableNatBTreeScanLimitResult({
        results = [];
        nextKey = null;
      }))
    ),
    S.suite("with BTree as leaf", [
      S.test("if the lower bound is greater than the greatest key in the tree returns the empty response",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            4,
            7,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and bounds exactly contain all elements",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            1,
            3,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(3, 3), (2, 2), (1, 1)];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and lower bound equals upper bound",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            2,
            2,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(2, 2)];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and bounds are from first to middle element",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            0,
            2,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(2, 2), (1, 1)];
          nextKey = null;
        }))
      ),
      S.test("if limit is greater than the result set and bounds are from middle to last element",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            2,
            4,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(3, 3), (2, 2)];
          nextKey = null;
        }))
      ),
      S.test("if limit is less than the result set",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            0,
            4,
            #bwd,
            2,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(3, 3), (2, 2)];
          nextKey = ?1;
        }))
      ),
      S.test("if there are gaps in the contents of the BTree (i.e. every other number) and the limit is less than the result set",
        do {
          let t = quickCreateBTreeWithKVPairs(8, Array.tabulate<Nat>(4, func(i) { i*2+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            0,
            6,
            #bwd,
            2,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [(5, 5), (3, 3)];
          nextKey = ?1;
        }))
      ),
    ]),
    S.suite("with BTree as multiple levels", [
      S.test("if lower bound is greater than the greatest key returns empty response",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
          BT.scanLimit(
            t,
            Nat.compare,
            40,
            50,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [];
          nextKey = null;
        }))
      ),
      S.test("if upper bound is lower than the lower key returns empty response",
        do {
          let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+10 }));
          BT.scanLimit(
            t,
            Nat.compare,
            1,
            9,
            #bwd,
            5,
          )
        },
        M.equals(BTM.testableNatBTreeScanLimitResult({
          results = [];
          nextKey = null;
        }))
      ),
      S.suite("if the limit is greater than the result set", [
        S.test("if bounds contain all elements",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 1);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to a middle leaf element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              7,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(7, 1);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to a end leaf element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              17,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(17, 1);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to an internal kv",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              21,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(21, 1);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the last element to right before a root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(5, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              6,
              10,
              #bwd,
              2,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(9, 9), (7, 7)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to an root internal kv",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              9,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(9, 1);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a 3-level root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              18,
              24,
              #bwd,
              3,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(23, 23), (21, 21), (19, 19)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a first non-root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              12,
              20,
              #bwd,
              4,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(19, 19), (17, 17), (15, 15), (13, 13)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to right before a last non-root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is equal to the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              6,
              14,
              #bwd,
              4,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(13, 13), (11, 11), (9, 9), (7, 7)];
            nextKey = null;
          }))
        ),
        S.test("if bounds are from the first to an root internal kv, there are gaps in the contents of the BTree (i.e. every other number), and the limit is less than the result set",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(4, func(i) { i*2+1 }));
            BT.scanLimit(
              t,
              Nat.compare,
              0,
              6,
              #bwd,
              2,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = [(5, 5), (3, 3)];
            nextKey = ?1;
          }))
        ),
        S.test("if bounds are from a middle leaf element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              10,
              31,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 10);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a last leaf element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              23,
              31,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 23);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a middle internal element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              6,
              31,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 6);
            nextKey = null;
          }))
        ),
        S.test("if bounds are from a root internal element to the last element",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              18,
              31,
              #bwd,
              40,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 18);
            nextKey = null;
          }))
        ),
      ]),
      S.suite("if the limit is less than the result set", [
        S.test("if bounds contain all elements and stop on a leaf kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              9,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 23);
            nextKey = ?22;
          }))
        ),
        S.test("if bounds contain all elements and stop on a leaf kv with next key being a internal key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              16,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 16);
            nextKey = ?15;
          }))
        ),
        S.test("if bounds contain all elements and stop on a leaf kv with next key being a root key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              22,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 10);
            nextKey = ?9;
          }))
        ),
        S.test("if bounds contain all elements and stop on an internal kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              20,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 12);
            nextKey = ?11;
          }))
        ),
        S.test("if bounds contain all elements and stop on an end internal kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              17,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 15);
            nextKey = ?14;
          }))
        ),
        S.test("if bounds contain all elements and stop on an root kv with next key being a leaf key",
          do {
            let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(31, func(i) { i+1 }));
            BT.scanLimit<Nat, Nat>(
              t,
              Nat.compare,
              0,
              40,
              #bwd,
              14,
            )
          },
          M.equals(BTM.testableNatBTreeScanLimitResult({
            results = quickCreateNatResultSetReverse(31, 18);
            nextKey = ?17;
          }))
        ),
      ]),
    ]),
  ]),
]);

let toArraySuite = S.suite("toArray", [
  S.test("if the tree is empty",
    do {
      let t = BT.init<Nat, Nat>(null);
      BT.toArray(t)
    },
    M.equals(T.array<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      [],
    ))
  ),
  S.test("if the tree root is a partially full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(2, func(i) { i+1 }));
      BT.toArray(t)
    },
    M.equals(T.array<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      [
        (1, 1),
        (2, 2),
      ],
    ))
  ),
  S.test("if the tree root is a completely full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
      BT.toArray(t)
    },
    M.equals(T.array<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      [
        (1, 1),
        (2, 2),
        (3, 3),
      ],
    ))
  ),
  S.suite("if the tree root is an internal node with multiple levels", [
    S.test("if the items were all inserted in order without any deletion",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        BT.toArray(t);
      },
      M.equals(T.array<(Nat, Nat)>(
        T.tuple2Testable(T.natTestable, T.natTestable),
        Array.tabulate<(Nat, Nat)>(22, func(i) { (i+1, i+1) }),
      ))
    ),
    S.test("if all the items were inserted in order with some deletion",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 12);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 13);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 14);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 16);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 18);
        BT.toArray(t);
      },
      M.equals(T.array<(Nat, Nat)>(
        T.tuple2Testable(T.natTestable, T.natTestable),
        [
          (1, 1),
          (2, 2),
          (3, 3),
          (4, 4),
          (5, 5),
          (6, 6),
          (7, 7),
          (8, 8),
          (9, 9),
          (10, 10),
          (15, 15),
          (17, 17),
          (19, 19),
          (20, 20),
          (21, 21),
          (22, 22),
        ],
      ))
    ),
    S.test("with a completely full multi-level tree",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [1,2,4,5,6,8,9,10,12,13,14,15,3,7,11]);
        BT.toArray(t);
      },
      M.equals(T.array<(Nat, Nat)>(
        T.tuple2Testable(T.natTestable, T.natTestable),
        Array.tabulate<(Nat, Nat)>(15, func(i) { (i+1, i+1) }),
      ))
    ),
  ]),
]);

let entriesSuite = S.suite("entries", [
  S.test("if the tree is empty, returns an empty iterator",
    do {
      let t = BT.init<Nat, Nat>(null);
      Iter.toArray(BT.entries(t));
    },
    M.equals(T.array<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      [],
    ))
  ),
  S.test("if the tree root is a partially full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(2, func(i) { i+1 }));
      Iter.toArray(BT.entries(t))
    },
    M.equals(T.array<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      [
        (1, 1),
        (2, 2),
      ],
    ))
  ),
  S.test("if the tree root is a completely full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
      Iter.toArray(BT.entries(t))
    },
    M.equals(T.array<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      [
        (1, 1),
        (2, 2),
        (3, 3),
      ],
    ))
  ),
  S.suite("if the tree root is an internal node with multiple levels", [
    S.test("if the items were all inserted in order without any deletion",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        Iter.toArray(BT.entries(t));
      },
      M.equals(T.array<(Nat, Nat)>(
        T.tuple2Testable(T.natTestable, T.natTestable),
        Array.tabulate<(Nat, Nat)>(22, func(i) { (i+1, i+1) }),
      ))
    ),
    S.test("if all the items were inserted in order with some deletion",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 12);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 13);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 14);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 16);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 18);
        Iter.toArray(BT.entries(t));
      },
      M.equals(T.array<(Nat, Nat)>(
        T.tuple2Testable(T.natTestable, T.natTestable),
        [
          (1, 1),
          (2, 2),
          (3, 3),
          (4, 4),
          (5, 5),
          (6, 6),
          (7, 7),
          (8, 8),
          (9, 9),
          (10, 10),
          (15, 15),
          (17, 17),
          (19, 19),
          (20, 20),
          (21, 21),
          (22, 22),
        ],
      ))
    ),
    S.test("with a completely full multi-level tree",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [1,2,4,5,6,8,9,10,12,13,14,15,3,7,11]);
        Iter.toArray(BT.entries(t));
      },
      M.equals(T.array<(Nat, Nat)>(
        T.tuple2Testable(T.natTestable, T.natTestable),
        Array.tabulate<(Nat, Nat)>(15, func(i) { (i+1, i+1) }),
      ))
    ),
  ]),
]);

let minSuite = S.suite("min", [
  S.test("if the tree is empty, returns None",
    do {
      let t = BT.init<Nat, Nat>(null);
      BT.min(t);
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      null
    ))
  ),
  S.test("if the tree root is a partially full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(2, func(i) { i+1 }));
      BT.min(t)
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(1, 1),
    ))
  ),
  S.test("if the tree root is a completely full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
      BT.min(t)
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(1, 1),
    ))
  ),
  S.test("if the tree root is an internal node with multiple levels",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
      BT.min(t);
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(1, 1),
    ))
  ),
  S.test("if the tree root is an internal node with multiple levels and some deletion",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 1);
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
      BT.min(t);
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(5, 5),
    ))
  ),
]);

let maxSuite = S.suite("max", [
  S.test("if the tree is empty, returns None",
    do {
      let t = BT.init<Nat, Nat>(null);
      BT.max(t);
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      null
    ))
  ),
  S.test("if the tree root is a partially full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(2, func(i) { i+1 }));
      BT.max(t)
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(2, 2),
    ))
  ),
  S.test("if the tree root is a completely full leaf",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(3, func(i) { i+1 }));
      BT.max(t)
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(3, 3),
    ))
  ),
  S.test("if the tree root is an internal node with multiple levels",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
      BT.max(t);
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(22, 22),
    ))
  ),
  S.test("if the tree root is an internal node with multiple levels and some deletion",
    do {
      let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 22);
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 21);
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
      ignore BT.delete<Nat, Nat>(t, Nat.compare, 19);
      BT.max(t);
    },
    M.equals(T.optional<(Nat, Nat)>(
      T.tuple2Testable(T.natTestable, T.natTestable),
      ?(18, 18),
    ))
  ),
]);

S.run(S.suite("BTree",
  [
    initSuite,
    getSuite,
    insertSuite,
    substituteKeySuite,
    updateSuite,
    deleteSuite,
    scanLimitSuite,
    toArraySuite,
    entriesSuite,
    minSuite,
    maxSuite,
  ]
));