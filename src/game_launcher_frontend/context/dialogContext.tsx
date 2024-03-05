import { Context, createContext } from "react";
import { DialogWidthType, DialogPropTypes } from "../types/dialogTypes";

const dialogContext: Context<DialogPropTypes> = createContext({
  openDialog: (args: {
    title: string;
    okCallback: () => void;
    cancelCallback?: () => void;
    width?: DialogWidthType;
    okText?: string;
    cancelText?: string;
  }) => {
    console.log(args);
  },
  closeDialog: () => {}
});

export default dialogContext;
