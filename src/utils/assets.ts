import { useAssetClient, useGameClient } from "@/hooks";
import { Base64, CreateGameFiles, GameFile } from "@/types";

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

  for (let i = 0; i < files.length; i++) {
    const batch = (await actor[methods.create_batch]()) as {
      batch_id: number;
    };
    const file = files[i];
    const chunks = [];

    for (let i = 0; i < file.fileArr.length; i++) {
      const _req2 = {
        content: file.fileArr[i],
        batch_id: Number(batch.batch_id),
      };

      const chunk = (await actor[methods.create_chunk](_req2)) as {
        chunk_id: number;
      };

      chunks.push(Number(chunk.chunk_id));
    }
    let n = trim_folder_name(file.fileName);
    let _name = String(encodeURI(n));
    if (_name == "/index.html") {
      _name = "/";
    }

    let _bch = brotli_compression_header(_name);
    let _gch = gzip_compression_header(_name);
    const etag = Math.random();

    if (_bch == "" && _gch == "") {
      await actor[methods.commit_asset_upload](
        batch.batch_id,
        String(_name),
        file.fileType,
        chunks,
        "identity",
        etag.toString(),
      );
    } else if (_gch != "") {
      await actor[methods.commit_asset_upload](
        batch.batch_id,
        String(_name),
        String(_gch),
        chunks,
        "gzip",
        etag.toString(),
      );
    } else {
      await actor[methods.commit_asset_upload](
        batch.batch_id,
        String(_name),
        String(_bch),
        chunks,
        "br",
        etag.toString(),
      );
    }
  }
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
  const download_url = "https://" + canister_id + ".raw.ic0.app/download";

  const content =
    '<!DOCTYPE html><html lang="en"><head><title>' +
    name +
    '</title></head><body><div style="text-align:center; margin-top:10vh"><div style="font-size:30px">' +
    name +
    '</div><div style="font-size:30px">' +
    description +
    '</div><img src="' +
    cover +
    '" style="width:200px"></img><div><a href="' +
    download_url +
    '">Download Game</a></div></div></body></html>';

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
