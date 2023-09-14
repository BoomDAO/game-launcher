let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.10.0-20230911/package-set.dhall sha256:7bce6afe8b96a8808f66b5b6f7015257d44fc1f3e95add7ced3ccb7ce36e5603
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }


let additions = [
  { name = "base"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "moc-0.7.2"
  , dependencies = [ "base" ]
  },
  { name = "matchers"
  , repo = "https://github.com/kritzcreek/motoko-matchers.git"
  , version = "v1.3.0"
  , dependencies = [ "base" ]
  },
  { name = "BTree"
  , repo = "https://github.com/canscale/StableHeapBTreeMap.git"
  , version = "v0.3.2"
  , dependencies = [ "base", "matchers" ]
  }
] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides
