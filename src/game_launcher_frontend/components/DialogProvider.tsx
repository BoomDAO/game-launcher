import React from "react";
import Dialog from "@mui/material/Dialog";
import DialogTitle from "@mui/material/DialogTitle";
import DialogActions from "@mui/material/DialogActions";
import DialogContent from "@mui/material/DialogContent";
import dialogContext from "../context/dialogContext";
import {
    DialogWidthType,
    DialogPropTypes,
    OpenDialogType,
    EmptyFunctionType
} from "../types/dialogTypes";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { navPaths } from "@/shared";
import EmailPage from "../pages/GamingGuilds/EmailPage";

interface StateTypes {
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

interface PropTypes {
    children: React.ReactNode;
    state: StateTypes;
}

const DialogProvider = (props: PropTypes) => {
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
    };

    const [state, setState] = React.useState<StateTypes>(props.state);

    const handleCloseClick = () => {
        if (state.cancelCallback) {
            setState({ isOpen: false });
            state.cancelCallback();
        } else {
            close();
        }
    };

    return (
        <dialogContext.Provider value={state.value}>
            <Dialog
                open={state.isOpen}
                onClose={handleCloseClick}
                maxWidth="md"
                fullWidth
                className=""
                sx={{
                    ".MuiDialog-paper": {
                        borderRadius: "12px",
                    },
                }}
            >
                <div className="gradient-bg rounded-xl w-full cursor-pointer p-0.5 ">
                    <div className="w-full rounded-xl bg-white">
                        <DialogTitle className="text-center">{state.title}</DialogTitle>
                        <DialogContent className="text-center">
                            {state.component}
                        </DialogContent>
                        <DialogActions>
                            <Button onClick={handleCloseClick} color="secondary">
                                Cancel
                            </Button>
                        </DialogActions>
                    </div>
                </div>
            </Dialog>
            {props.children}
        </dialogContext.Provider>
    )
}

export default DialogProvider;
