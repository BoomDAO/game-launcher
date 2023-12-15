import React from "react";
import { Subtract } from "utility-types";
import { DialogPropTypes } from "../types/dialogTypes";
import dialogContext from "../context/dialogContext";

const WithDialog = <Props extends DialogPropTypes>(
  Component: React.ComponentType<Props>
): React.ComponentType<Subtract<Props, DialogPropTypes>> => {
  return class C extends React.Component<Subtract<Props, DialogPropTypes>> {
    render() {
      return (
        <dialogContext.Consumer>
          {(context) => (
            <Component
              {...(this.props as Props)}
              openDialog={context.openDialog}
              closeDialog={context.closeDialog}
            />
          )}
        </dialogContext.Consumer>
      );
    }
  };
};

export default WithDialog;
