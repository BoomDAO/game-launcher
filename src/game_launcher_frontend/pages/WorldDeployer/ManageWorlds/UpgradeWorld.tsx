// import React, { useState } from "react";
// import { useForm } from "react-hook-form";
// import { useTranslation } from "react-i18next";
// import { useParams } from "react-router-dom";
// import { zodResolver } from "@hookform/resolvers/zod";
// import { z } from "zod";
// import UploadGameHint from "@/components/UploadGameHint";
// import Form from "@/components/form/Form";
// import FormSelect from "@/components/form/FormSelect";
// import FormTextArea from "@/components/form/FormTextArea";
// import FormTextInput from "@/components/form/FormTextInput";
// import FormUploadButton from "@/components/form/FormUploadButton";
// import Button from "@/components/ui/Button";
// import H1 from "@/components/ui/H1";
// import Space from "@/components/ui/Space";
// import { WorldWasm } from "@/types";
// import SubHeading from "@/components/ui/SubHeading";
// import { useGetAvailableWorldVersion, useGetCurrentWorldVersion, useUpgradeWorld } from "@/api/world_deployer";

// const scheme = z
//   .object({
//     wasm: z.string().min(1, "Wasm File is required."),
//   });

// type Form = z.infer<typeof scheme>;

// const UpgradeWorld = () => {
//   const { canisterId } = useParams();

//   const { t } = useTranslation();

//   const { data: currentWorld } = useGetCurrentWorldVersion(canisterId);
//   const { data: availableWorld } = useGetAvailableWorldVersion();

//   const { mutate, isLoading: isLoadingUpgradeWorld } = useUpgradeWorld();

//   return (
//     <>
//       <SubHeading>What is upgrading a World?</SubHeading>
//       <br></br>
//       Upgrading World means upgrade code of your World canister to get all latest features, changes and bug fixes.
//       You can download latest release of World wasm file directly from our <a className="underline text-yellow-300" href="https://github.com/BoomDAO/game-launcher/tree/main/wasm_modules">Game Launcher github repo</a>. Use the wasm file below to upgrade your World canister.
//       <br></br>
//       <div className="">
//         <SubHeading>Your World Version : {currentWorld}</SubHeading>
//         <br></br>
//         <SubHeading>Available World Version : {availableWorld}</SubHeading>
//       </div>
//       {/* <SubHeading>{t("world_deployer.manage_worlds.tabs.item_4.title")}</SubHeading> */}
//       <div className="grid grid-cols-1 gap-1 md:grid-cols-2">
//         <Button
//           rightArrow
//           size="big"
//           isLoading={isLoadingUpgradeWorld}
//           onClick={() => mutate({ canisterId })}
//         >
//           {t("world_deployer.manage_worlds.tabs.item_4.upgrade_world.upgrade_world_button")}
//         </Button>
//       </div>
//     </>
//   );
// };

// export default UpgradeWorld;
