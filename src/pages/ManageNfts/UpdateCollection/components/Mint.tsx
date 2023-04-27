import React from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const Mint = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.airdrop.title")}</SubHeading>
      <Space />
    </div>
  );
};

export default Mint;
