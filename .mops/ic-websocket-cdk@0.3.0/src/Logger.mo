import Text "mo:base/Text";
import Debug "mo:base/Debug";

module {
  public func custom_print(s : Text) {
    Debug.print(Text.concat("[IC-WEBSOCKET-CDK]: ", s));
  };
};
