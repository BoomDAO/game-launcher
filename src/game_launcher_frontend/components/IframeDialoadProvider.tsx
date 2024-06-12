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
import CloseIcon from '@mui/icons-material/Close';
import FullscreenIcon from '@mui/icons-material/Fullscreen';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import IconButton from '@mui/material/IconButton';
import CloseFullscreenIcon from '@mui/icons-material/CloseFullscreen';
import { cx } from "../utils/common";

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

const IframeDialogProvider = (props: PropTypes) => {
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
    const [isFullscreen, setFullscreen] = React.useState(false);

    const handleCloseClick = () => {
        if (state.cancelCallback) {
            setState({ isOpen: false });
            state.cancelCallback();
        } else {
            close();
        }
    };

    const handleNewTabClick = () => {
        let gameUrl = "https://" + state.title + ".raw.icp0.io";
        window.open(gameUrl, "_blank");
    };

    return (
        <dialogContext.Provider value={state.value}>
            <Dialog
                id="dialog"
                open={state.isOpen}
                onClose={handleCloseClick}
                fullScreen
                // className={cx(
                //     isFullscreen ? "m-0" : "m-24"
                // )}
                sx={{
                    ".MuiDialog-paper": {
                        borderRadius: "8px",
                    },
                }}
            >
                <div className="w-full h-full cursor-pointer">
                    <div className="w-full h-full bg-white dark:bg-dark">
                        <DialogContent className="text-center !py-10 m-0">
                            {state.component}
                        </DialogContent>
                        <div className="flex">
                            {/* {
                                (isFullscreen) ? <DialogActions className="absolute top-1 gradient-bg rounded-full !p-0 !pr-0.5" style={{right:"76px"}}>
                                    <IconButton onClick={() => setFullscreen(false)} color="info" size="small" edge="end">
                                        <CloseFullscreenIcon />
                                    </IconButton>
                                </DialogActions> : <DialogActions className="absolute top-1 gradient-bg rounded-full !p-0 !pr-0.5" style={{right:"76px"}}>
                                    <IconButton onClick={() => setFullscreen(true)} color="info" size="small" edge="end">
                                        <FullscreenIcon />
                                    </IconButton>
                                </DialogActions>
                            } */}
                            <DialogActions className="absolute top-1 right-16 gradient-bg rounded-full !p-0 !pr-0.5">
                                <IconButton onClick={handleNewTabClick} color="info" size="small" edge="end">
                                    <OpenInNewIcon />
                                </IconButton>
                            </DialogActions>
                            <DialogActions className="absolute top-1 right-6 gradient-bg rounded-full !p-0 !pr-0.5">
                                <IconButton onClick={handleCloseClick} color="info" size="small" edge="end">
                                    <CloseIcon />
                                </IconButton>
                            </DialogActions>
                        </div>
                    </div>
                </div>
            </Dialog>
        </dialogContext.Provider>
    )
}

export default IframeDialogProvider;
