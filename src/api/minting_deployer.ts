import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Principal } from "@dfinity/principal";
import {
  UseQueryResult,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { useAuthContext } from "@/context/authContext";
import { useExtClient, useMintingDeployerClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import { Collection, CreateCollection } from "@/types";

export const queryKeys = {
  collections: "collections",
};

export const useGetCollections = (): UseQueryResult<Collection[]> => {
  const { session } = useAuthContext();

  return useQuery({
    queryKey: [queryKeys.collections],
    queryFn: async () => {
      const { actor, methods } = await useMintingDeployerClient();
      return await actor[methods.get_collections](session?.address);
    },
  });
};

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

export const useGetTokenRegistry = () =>
  useMutation({
    mutationFn: async ({
      canisterId,
      page = 0,
    }: {
      canisterId?: string;
      page?: number;
    }) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();
        const data = (await actor[methods.getRegistry](
          canisterId,
          page,
        )) as string[];

        return data;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useGetTokenMetadata = () =>
  useMutation({
    mutationFn: async ({
      canisterId,
      index,
    }: {
      canisterId?: string;
      index: string;
    }) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();
        const metadata = (await actor[methods.getTokenMetadata](
          canisterId,
          parseInt(index, 10),
        )) as string;

        const tokenUrl = (await actor[methods.getTokenUrl](
          canisterId,
          parseInt(index, 10),
        )) as string;

        return { metadata, tokenUrl };
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useAddAdmin = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useExtClient(canisterId);

        return await actor[methods.add_admin](Principal.fromText(principal));
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.admin.add.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.admin.add.success"));
    },
  });
};

export const useRemoveAdmin = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useExtClient(canisterId);

        return await actor[methods.remove_admin](Principal.fromText(principal));
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.admin.remove.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.admin.remove.success"));
    },
  });
};

export const useAddController = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();

        return await actor[methods.add_controller](canisterId, principal);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.controller.add.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.controller.add.success"));
    },
  });
};

export const useRemoveController = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();

        return await actor[methods.remove_controller](canisterId, principal);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.controller.remove.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.controller.remove.success"));
    },
  });
};

export const useBurnNft = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      index,
      canisterId,
    }: {
      index: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();

        return await actor[methods.external_burn](
          canisterId,
          parseInt(index, 10),
        );
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.burn.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.burn.success"));
    },
  });
};
