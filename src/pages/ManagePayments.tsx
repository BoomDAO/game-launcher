import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";

const ManagePayments = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <div>
      <Space size="medium" />

      <div className="flex flex-col items-center justify-center gap-12 rounded-primary border border-black p-12 text-center dark:border-white">
        <p className="text-xl">{t("manage_payments.text")}</p>

        <Button
          rightArrow
          size="big"
          onClick={() => navigate(`${navPaths.manage_payments}`)}
        >
          {t("manage_payments.button")}
        </Button>
      </div>
    </div>
  );
};

export default ManagePayments;
