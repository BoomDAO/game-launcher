import { useAssetClient, useGameClient } from "@/hooks";
import { Base64, CreateGameFiles, GameFile, CreateChunkType } from "@/types";

export const b64toArrays = (base64: Base64) => {
  let encoded = base64.toString().replace(/^data:(.*,)?/, "");

  if (encoded.length % 4 > 0) {
    encoded += "=".repeat(4 - (encoded.length % 4));
  }

  const byteCharacters = Buffer.from(encoded, "base64");
  const byteArrays = [];
  const sliceSize = 1500000;

  for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
    const byteArray = [];
    let x = offset + sliceSize;
    if (byteCharacters.length < x) {
      x = byteCharacters.length;
    }
    for (let i = offset; i < x; i++) {
      byteArray.push(byteCharacters[i]);
    }
    byteArrays.push(byteArray);
  }

  return byteArrays;
};

export const b64toType = (base64: Base64) => {
  let type = "";
  let encode = base64.toString();
  let f = false;

  for (let i = 0; i < encode.length; i++) {
    if (encode[i] == ":") {
      f = true;
    } else if (f && encode[i] != ";") {
      type += encode[i];
    }
    if (encode[i] == ";") {
      break;
    }
  }

  return type;
};

export const trim_folder_name = (name: string) => {
  let res = "";
  let index = 0;

  for (let i = 0; i < name.length; i++) {
    if (name[i] == "/") {
      index = i;
      break;
    }
  }
  for (let i = index; i < name.length; i++) {
    res = res + name[i];
  }

  return res;
};

const reverse = (str: string) => {
  return str.split("").reverse().join("");
};

export const brotli_compression_header = (name: string) => {
  let r = "";
  let dot = false;

  for (let i = name.length - 1; i >= 0; i--) {
    if (dot == false && name[i] == ".") {
      dot = true;
    } else if (dot == true && name[i] == ".") {
      break;
    }
    r = r + name[i];
  }

  if (reverse(r) == "js.br") {
    return "application/javascript";
  } else if (reverse(r) == "data.br") {
    return "application/javascript";
  } else if (reverse(r) == "wasm.br") {
    return "application/wasm";
  } else {
    return "";
  }
};

export const gzip_compression_header = (name: string) => {
  let r = "";
  let dot = false;

  for (let i = name.length - 1; i >= 0; i--) {
    if (dot == false && name[i] == ".") {
      dot = true;
    } else if (dot == true && name[i] == ".") {
      break;
    }
    r = r + name[i];
  }
  if (reverse(r) == "js.gz") {
    return "application/javascript";
  } else if (reverse(r) == "data.gz") {
    return "application/javascript";
  } else if (reverse(r) == "wasm.gz") {
    return "application/wasm";
  } else {
    return "";
  }
};

export const getGameFiles = async (file: File) => {
  return new Promise<GameFile>((resolve, reject) => {
    const reader = new FileReader();
    // Convert the file to base64 text
    reader.readAsDataURL(file);

    reader.onloadend = async () => {
      if (reader.result === null) {
        throw new Error("file empty...");
      }

      let encoded = reader.result.toString().replace(/^data:(.*,)?/, "");

      if (encoded.length % 4 > 0) {
        encoded += "=".repeat(4 - (encoded.length % 4));
      }

      const fileArr = b64toArrays(reader.result);
      const fileType = b64toType(reader.result);
      const fileName = file.webkitRelativePath;

      resolve({ fileName, fileType, fileArr });
    };
  });
};

export const uploadGameFiles = async (
  canisterId: string,
  files: GameFile[],
) => {
  const { actor, methods } = await useAssetClient(canisterId);

  const r = {};
  await actor[methods.clear](r);
  console.log("Cleared State!");
  let commits = [];
  for (let i = 0; i < files.length; i++) {
    console.log(files[i]);
    const batch = (await actor[methods.create_batch]()) as {
      batch_id: number;
    };
    const file = files[i];
    let chunks = [];
    let chunkIds : Number[] = [];
    for (let i = 0; i < file.fileArr.length; i++) {
      const _req2 = {
        content: file.fileArr[i],
        batch_id: Number(batch.batch_id),
      };
      chunks.push(actor[methods.create_chunk](_req2));
    }
    await Promise.all(chunks)
      .then(
        (res2: any) => {
          for (let k = 0; k < res2.length; k++) {
            chunkIds.push(Number(res2[k].chunk_id));
          };
          return chunkIds;
        }
      )
      .then(
        response => {
          chunks = response;
        }
      )
    console.log(chunks);

    let n = trim_folder_name(file.fileName);
    let _name = String(encodeURI(n));
    if (_name == "/index.html") {
      _name = "/";
    }
    console.log(_name);
    let _bch = brotli_compression_header(_name);
    let _gch = gzip_compression_header(_name);
    const etag = Math.random();

    if (_bch == "" && _gch == "") {
      commits.push(
        actor[methods.commit_asset_upload](
          batch.batch_id,
          String(_name),
          file.fileType,
          chunks,
          "identity",
          etag.toString(),
        )
      );
    } else if (_gch != "") {
      commits.push(
        actor[methods.commit_asset_upload](
          batch.batch_id,
          String(_name),
          String(_gch),
          chunks,
          "gzip",
          etag.toString(),
        )
      );
    } else {
      commits.push(
        actor[methods.commit_asset_upload](
          batch.batch_id,
          String(_name),
          String(_bch),
          chunks,
          "br",
          etag.toString(),
        )
      );
    }
  }
  await Promise.all(commits).then((values) => {
    console.log(values);
  });
};

export const uploadZip = async ({
  canister_id,
  description,
  name,
  files,
}: CreateGameFiles) => {
  const { actor, methods } = await useAssetClient(canister_id);
  const { actor: gameActor, methods: gameMethods } = await useGameClient();

  const r = {};
  await actor.clear(r);
  console.log("Cleared State!");

  const cover = await gameActor[gameMethods.get_game_cover](canister_id);
  const download_url = "https://" + canister_id + ".raw.icp0.io/download";
  const boom_logo = "data:image/png;base64,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";

  const content = '<html><head><title>' + name +
    '</title><link href=\'https://fonts.googleapis.com/css?family=Poppins\' rel=\'stylesheet\'><style>body {font-family: \'Poppins\';margin: 0;padding: 0;background: url("' + cover + '");background-repeat: no-repeat;background-size: cover;backdrop-filter: blur(3px);}</style></head><body><div style="width: 100%;height: 100vh;"><div style="padding-top: 20px; padding-left: 40px; padding-bottom: 60px;"><a href="https://awcae-maaaa-aaaam-abmyq-cai.icp0.io/" target="_blank"><img src="' + boom_logo +
    '" alt="logo" style="width:164px;"/></a></div><div style="border:solid 2px rgb(255, 255, 255);border-radius: 40px; width: 40%;text-align: center; margin-left: 30%;padding: 20px 20px 30px 20px; background-color: white;"><h1 style="width: 60%; margin-left: 20%;">' + name +
    '</h1><img src="' + cover +
    '" alt="GameLogo" style="width: 60%; height: 20%; background-repeat: no-repeat;background-size: cover; margin-bottom:20px;" /><p style="width:70%; padding-left: 15%;"><b>' + description +
    '</b></p><p><b>Platform : </b> Android</p><div style="display: flex; justify-content: center; align-items: center;"><button style="display: flex; background-image:linear-gradient(90deg, #FEA002 7.32%, #E73BCF 100%); border: none; color: white; border-radius: 40px;"><a href="' + download_url +
    '" style="color: white; padding: 8px 0px 8px 50px; font-size: 18px;">DOWNLOAD GAME ON-CHAIN</a><svg style="padding: 10px 50px 0 15px;" width="16" height="16" viewBox="0 0 18 18" fill="none"xmlns="http://www.w3.org/2000/svg"><path d="M9.0001 1L9.00006 17M9.00006 17L17 9.04164M9.00006 17L1 8.95848" stroke="#F6F6F6"stroke-width="2" stroke-linecap="round" stroke-linejoin="round" /></svg></button></div></div></div></body></html>';

  // const blob = new Blob([content], { type: "text/html" });

  const enc = new TextEncoder();
  const arrayBuffer = enc.encode(content);

  const batch = (await actor[methods.create_batch]()) as { batch_id: number };
  const _chunks = [];
  const _r = {
    content: arrayBuffer,
    batch_id: Number(batch.batch_id),
  };

  const chunk = (await actor[methods.create_chunk](_r)) as { chunk_id: number };
  _chunks.push(Number(chunk.chunk_id));

  await actor[methods.commit_asset_upload](
    batch.batch_id,
    String("/"),
    "text/html",
    _chunks,
    "identity",
    "",
  );

  const batch1 = (await actor[methods.create_batch]()) as { batch_id: number };
  const file = files[0];
  const chunks = [];

  for (let i = 0; i < file.fileArr.length; i++) {
    const _req2 = {
      content: file.fileArr[i],
      batch_id: Number(batch1.batch_id),
    };

    const res2 = (await actor[methods.create_chunk](_req2)) as {
      chunk_id: number;
    };
    chunks.push(Number(res2.chunk_id));
  }

  const _name = "/download";

  await actor[methods.commit_asset_upload](
    batch1.batch_id,
    String(_name),
    file.fileType,
    chunks,
    "identity",
    "",
  );
};
