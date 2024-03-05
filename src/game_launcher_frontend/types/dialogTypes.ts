import React from "react";

export type DialogWidthType = "xl" | "lg" | "md" | "sm";

export interface StateTypes {
  component: React.ReactNode;
  value: DialogPropTypes;
  isOpen: boolean;
  title: string;
  okText?: string;
  cancelText?: string;
  width?: DialogWidthType;
  okCallback: EmptyFunctionType;
  cancelCallback?: EmptyFunctionType;
}

export type OpenDialogType = (args: {
  component: React.ReactNode;
  title: string;
  okCallback: () => void;
  cancelCallback: () => void;
  width?: DialogWidthType;
  okText?: string;
  cancelText?: string;
}) => void;

export interface DialogPropTypes {
  openDialog: OpenDialogType;
  closeDialog: EmptyFunctionType;
}

export type EmptyFunctionType = () => void;
