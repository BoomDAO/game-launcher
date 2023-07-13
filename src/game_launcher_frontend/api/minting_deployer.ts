import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";
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
import { Airdrop, Collection, CreateCollection, Mint, AssetUpload } from "@/types";
import { b64toType, arrayTob64, b64toArrays, formatCycleBalance, getAgent } from "@/utils";
// @ts-ignore
import { idlFactory as ExtFactory } from "../dids/ext.did.js";

export const queryKeys = {
  collections: "collections",
  collection_cycle_balance: "collection_cycle_balance",
  collecitons_total: "totalColections"
};

export const useGetTotalCollections = () =>
  useQuery({
    queryKey: [queryKeys.collecitons_total],
    queryFn: async () => {
      const { actor, methods } = await useMintingDeployerClient();
      return Number(await actor[methods.get_total_collections]());
    },
  });

export const useGetAllCollections = (page: number = 1): UseQueryResult<Collection[]> => {
  const { session } = useAuthContext();

  return useQuery({
    queryKey: [queryKeys.collections, page],
    queryFn: async () => {
      const { actor, methods } = await useMintingDeployerClient();
      return await actor[methods.get_all_collections](page - 1);
    },
  });
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

export const useAirdrop = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      canisterId,
      collectionId,
      metadata,
      nft,
      prevent,
      burnTime,
    }: Airdrop) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();
        const burn = burnTime
          ? BigInt(parseInt(burnTime, 10) * 1000000)
          : BigInt(0);
        return await actor[methods.airdrop_to_addresses](
          canisterId,
          collectionId,
          JSON.stringify(metadata),
          prevent,
          burn,
          nft
        );
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.airdrop.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.airdrop.success"));
    },
  });
};

export const useMint = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      canisterId,
      principals,
      metadata,
      nft,
      burnTime,
      mintForAddress,
    }: Mint) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();

        const burn = burnTime
          ? BigInt(parseInt(burnTime, 10) * 1000000)
          : BigInt(0);

        const trimPrincipals = principals.replace(/\s/g, "");
        return await actor[methods.batch_mint_to_addresses](
          canisterId,
          trimPrincipals.split(","),
          JSON.stringify(metadata),
          parseInt(mintForAddress, 10),
          burn,
          nft
        );
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.mint.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.mint.success"));
    },
  });
};

export const useGetCollectionCycleBalance = (
  canisterId?: string,
  showCycles?: boolean,
): UseQueryResult<string> =>
  useQuery({
    enabled: !!canisterId && !!showCycles,
    queryKey: [queryKeys.collection_cycle_balance, canisterId],
    queryFn: async () => {
      const agent = await getAgent();
      const actor = Actor.createActor(ExtFactory, {
        agent,
        canisterId: canisterId!,
      });

      const balance = Number(await actor.availableCycles());
      return `${formatCycleBalance(balance)}T`;
    },
  });

export const useAssetUpload = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      canisterId,
      nft,
      assetId
    }: AssetUpload) => {
      try {
        const { actor, methods } = await useMintingDeployerClient();
        const chunk = (b64toArrays(nft))[0];
        return await actor[methods.upload_asset](
          canisterId,
          assetId,
          chunk
        );
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.assets.upload.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.assets.upload.success"));
    },
  });
};

export const useGetAssetIds = () =>
  useMutation({
    mutationFn: async ({
      canisterId,
    }: {
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useExtClient(canisterId);
        const data = (await actor[methods.get_asset_ids]()) as string[];
        return data;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useGetAssetEncoding = () =>
  useMutation({
    mutationFn: async ({
      canisterId,
      assetId
    }: {
      canisterId?: string;
      assetId: string;
    }) => {
      try {
        const { actor, methods } = await useExtClient(canisterId);
        const data = (await actor[methods.get_asset_encoding](assetId)) as [];
        const image = await arrayTob64(data);
        return image;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });
