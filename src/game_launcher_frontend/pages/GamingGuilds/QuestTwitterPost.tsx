import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { navPaths } from "@/shared";
import DialogProvider from "@/components/DialogProvider";
import GamingGuilds from ".";
import {
    OpenDialogType,
    StateTypes
} from "../../types/dialogTypes";
import TwitterPost from "./TwitterPost";

const QuestTwitterPost = () => {
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
        navigate(navPaths.gaming_guilds);
      };
    
      const [state, setState] = React.useState<StateTypes>({
        component: <TwitterPost/>,
        isOpen: true,
        title: "",
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
            <DialogProvider state={state}>
                <GamingGuilds />
            </DialogProvider>
        </>
    );
}

export default QuestTwitterPost;
