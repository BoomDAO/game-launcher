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
import { useVerifyEmail } from "@/api/guilds";
import GameIframe from "./GameIframe";
import IframeDialogProvider from "@/components/IframeDialoadProvider";
import Home from "../Home";

const scheme = z.object({
    email: z.string().min(1, "Email is required."),
    otp: z.string().min(1, "OTP is required."),
});
type Data = z.infer<typeof scheme>;

const Iframe = () => {
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
        navigate(navPaths.home);
      };
    
      const [state, setState] = React.useState<StateTypes>({
        component: <GameIframe/>,
        isOpen: true,
        title: canisterId || "",
        okText: "Ok",
        cancelText: "Cancel",
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
            <IframeDialogProvider state={state}>
                <Home/>
            </IframeDialogProvider>
        </>
    );
}

export default Iframe;
