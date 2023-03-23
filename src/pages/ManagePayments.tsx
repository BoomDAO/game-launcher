import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import Button from "@/components/Button";
import Space from "@/components/Space";
import { navPaths } from "@/shared";

const ManagePayments = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <div>
      <Space size="medium" />

      <div className="flex flex-col items-center justify-center gap-12 rounded-primary border border-black p-12 text-center dark:border-white">
        <p className="text-xl">{t("manage_payments_msg")}</p>

        <Button
          rightArrow
          size="big"
          onClick={() => navigate(`${navPaths.manage_payments}`)}
        >
          {t("deploy_payment_canister")}
        </Button>
      </div>
    </div>
  );
};

export default ManagePayments;
