import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { navPaths } from "@/shared";
import DialogProvider from "@/components/DialogProvider";
import {
    DialogWidthType,
    DialogPropTypes,
    OpenDialogType,
    EmptyFunctionType,
    StateTypes
} from "../../types/dialogTypes";
import TransferPage from "./TransferPage";
import NftTransferPage from "./NftTransferPage";
import Nft from "./Nft";
import Wallet from ".";

const WalletTransfer = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();

    const open: OpenDialogType = ({
        component,
        title,
        okCallback,
        cancelCallback,
        width,
        okText,
        cancelText
      }) => {
        setState({
          component,
          title,
          okCallback,
          cancelCallback,
          width,
          okText,
          cancelText,
          isOpen: true,
          value: {
            openDialog: open,
            closeDialog: close
          }
        });
      };
    
      const close = (): void => {
        setState({ isOpen: false });
        navigate(navPaths.wallet_nfts);
      };
    
      const [state, setState] = React.useState<StateTypes>({
        component: <NftTransferPage />,
        isOpen: true,
        title: "",
        okText: "Ok",
        cancelText: "Close",
        width: "md",
        okCallback: close,
        cancelCallback: close,
        value: {
          openDialog: open,
          closeDialog: close
        }
      });

    return (
        <>
            <DialogProvider state={state}>
                <Wallet activeTab="Nfts"/>
            </DialogProvider>
        </>
    );
}

export default WalletTransfer;
