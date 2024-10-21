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
import Wallet from "./";
import LaunchpadProject from "./LaunchpadProject";
import ParticipateTransfer from "./ParticipateTransfer";

const Participate = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { canisterId } = useParams();

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
        navigate(navPaths.launchpad + "/" + canisterId);
      };
    
      const [state, setState] = React.useState<StateTypes>({
        component: <ParticipateTransfer />,
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
                <LaunchpadProject/>
            </DialogProvider>
        </>
    );
}

export default Participate;
