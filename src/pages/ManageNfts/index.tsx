import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import { useGetCollections } from "@/api/minting_deployer";
import Card from "@/components/Card";
import EmptyGameCard from "@/components/EmptyGameCard";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";

const ManageNfts = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data: collections = [], isLoading, isError } = useGetCollections();

  console.log("collections", collections);

  return (
    <>
      <Space size="medium" />

      <Button
        size="big"
        rightArrow
        onClick={() => navigate(`${navPaths.manage_nfts_new}`)}
      >
        {t("manage_nfts.button")}
      </Button>

      <Space />

      <H1>{t("manage_nfts.title")}</H1>

      <Space size="medium" />

      {isLoading ? (
        <LoadingResult>{t("upload_games.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("error")}</ErrorResult>
      ) : collections.length ? (
        <>
          <div className="card-container">
            {collections.map(({ canister_id, name }) => (
              <Card
                key={canister_id}
                icon={<Cog8ToothIcon />}
                title={name}
                canisterId={canister_id}
                showCycles
                onClick={() =>
                  navigate(`${navPaths.manage_nfts}/${canister_id}`)
                }
              />
            ))}
            <EmptyGameCard length={collections.length} />
          </div>
        </>
      ) : (
        <NoDataResult>{t("upload_games.no_games")}</NoDataResult>
      )}
    </>
  );
};

export default ManageNfts;
