import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
    useCreateGameFiles,
    useGetGame,
    useUpdateGameCover,
    useUpdateGameData,
    useUpdateGameSubmit,
    useUpdateGameVisibility,
} from "@/api/games_deployer";
import {
    ErrorResult,
    LoadingResult,
    PreparingForUpload,
    UploadResult,
} from "@/components/Results";
import UploadGameHint from "@/components/UploadGameHint";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { visibility_types } from "@/shared";
import { GameVisibility } from "@/types";

const scheme = z.object({
    visibility: z.string().min(1, "Visibility are required."),
});

type Data = z.infer<typeof scheme>;

const Visibility = () => {
    const { canisterId } = useParams();

    const { t } = useTranslation();
    const { control, handleSubmit, watch, reset } = useForm<Data>({
        defaultValues: {
            visibility: "public",
        },
        resolver: zodResolver(scheme),
    });
    const visibility = watch("visibility");

    const { mutate, isLoading } = useUpdateGameVisibility((canisterId != undefined)? canisterId : "");

    const onSubmit = (values: Data) => {
        mutate(
            { ...values },
            {
                onSuccess: () => reset(),
            },
        );
    }

    return (
        <>
            <H1>{t("upload_games.Game.tab_2.title")}</H1>
            <Form onSubmit={handleSubmit(onSubmit)}>
                <div className="w-6/12">
                    <FormSelect
                        data={visibility_types}
                        control={control}
                        name="visibility"
                    />
                </div>

                <Button
                    size="big" isLoading={isLoading}
                >
                    {t("upload_games.Game.tab_2.button")}
                </Button>
            </Form>
        </>
    );
};

export default Visibility;
