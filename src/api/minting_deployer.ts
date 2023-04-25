import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import {
  UseQueryResult,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { useAuthContext } from "@/context/authContext";
import { useMintingDeployerClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import { Collection, CreateCollection } from "@/types";

export const queryKeys = {
  collections: "collections",
  cycle_balance: "cycle_balance",
};

export const useGetCollections = (): UseQueryResult<Collection[]> =>
  useQuery({
    queryKey: [queryKeys.collections],
    queryFn: async () => {
      const { actor, methods } = await useMintingDeployerClient();
      return await actor[methods.get_collections]();
    },
  });

export const useCreateCollection = () => {
  const { session } = useAuthContext();
  const { t } = useTranslation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (payload: CreateCollection) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();

        const canisterId = (await actor[methods.create_collection](
          payload.name,
          session?.address,
          payload.description,
          BigInt(0),
        )) as string;

        return canisterId;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.create.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.create.success"));
      queryClient.refetchQueries({ queryKey: [queryKeys.collections] });
      navigate(navPaths.manage_nfts);
    },
  });
};
