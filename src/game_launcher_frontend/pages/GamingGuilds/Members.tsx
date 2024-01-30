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
import H1 from "@/components/ui/H1";
import { useAuthContext } from "@/context/authContext";
import { useGetAllMembersInfo } from "@/api/guilds";
import { MembersInfo } from "@/types";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Space from "@/components/ui/Space";
import Pagination from "@/components/Pagination";

const Members = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [pageNumber, setPageNumber] = React.useState(1);
    const { data : totalMembersInfo = { totalMembers : "", members : [] }, isLoading, isError } = useGetAllMembersInfo();

    return (
        <>
            <div className="flex">
                <div className="flex">
                    <p className="text-3xl">Total Guild Members : </p>
                    <div className="text-4xl gradient-text ml-2">{ isLoading? <LoadingResult></LoadingResult> : totalMembersInfo.totalMembers}</div>
                </div>
                <div>
                </div>
            </div>
            <div className="w-full flex justify-around">
                <p className="w-1/4 text-xl">Profile Image</p>
                <p className="w-1/4 text-xl">Username</p>
                <p className="w-1/4 text-xl">Guild XP</p>
                <p className="w-1/4 text-xl">Join Date</p>
            </div>
            {/* <Space/> */}
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("gaming_guilds.items.item_2.loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    totalMembersInfo.members.length ? (
                        <>
                            <div className="w-full">
                                {totalMembersInfo.members.map(({ username, joinDate, image, guilds }) => (
                                    <div key={username}>
                                        <div className="flex justify-around my-2.5">
                                            <div className="w-1/4 pl-10"><img src={image} className="h-10 w-10 rounded-3xl" /></div>
                                            <p className="w-1/4 font-light pl-1 pt-2">{username}</p>
                                            <p className="w-1/4 font-light pl-1 pt-2">{guilds}</p>
                                            <p className="w-1/4 font-light pl-1 pt-2">{joinDate}</p>
                                        </div>
                                        <div className="w-full h-px gradient-bg opacity-25"></div>
                                    </div>
                                ))}
                            </div>

                            {/* <Pagination
                                pageNumber={pageNumber}
                                setPageNumber={setPageNumber}
                                totalNumbers={getPaginationPages(totalMembersInfo.members.length, 9)}
                            /> */}
                        </>
                    ) : (
                        <NoDataResult>{t("gaming_guilds.items.item_2.no_members")}</NoDataResult>
                    )}
            </div>
        </>
    );
}

export default Members;
