let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let packages = [
  { name = "base"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "moc-0.7.2"
  , dependencies = [ "base" ]
  },
  { name = "matchers"
  , repo = "https://github.com/kritzcreek/motoko-matchers.git"
  , version = "v1.3.0"
  , dependencies = [ "base" ]
  }
]: List Package

in packages
