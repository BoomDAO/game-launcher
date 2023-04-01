import { useAssetClient } from "@/hooks";

type Base64 = string | ArrayBuffer;

export interface GameFile {
  fileArr: number[][];
  fileName: string;
  fileType: string;
}

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

      console.log(fileName + " | " + Math.round(file.size / 1000) + " kB");
      resolve({ fileName, fileType, fileArr });
    };
  });
};

export const uploadGameFiles = async (canisterId: string, game: GameFile[]) => {
  const { actor, methods } = await useAssetClient(canisterId);

  const r = {};
  await actor[methods.clear](r);

  console.log("Cleared State!");

  for (let i = 0; i < game.length; i++) {
    console.log(game[i]);
    const res1 = (await actor[methods.create_batch]()) as {
      batch_id: number;
    };
    const file = game[i];
    const chunks = [];

    for (let i = 0; i < file.fileArr.length; i++) {
      const _req2 = {
        content: file.fileArr[i],
        batch_id: Number(res1.batch_id),
      };

      const res2 = (await actor[methods.create_chunk](_req2)) as {
        chunk_id: number;
      };
      chunks.push(Number(res2.chunk_id));
    }
    // console.log(chunks);
    let n = trim_folder_name(file.fileName);
    let _name = String(encodeURI(n));
    if (_name == "/index.html") {
      _name = "/";
    }
    console.log(_name);
    let _bch = brotli_compression_header(_name);
    let _gch = gzip_compression_header(_name);
    // console.log(_bch);
    // console.log(_gch);
    const etag = Math.random();
    console.log(etag);

    if (_bch == "" && _gch == "") {
      await actor[methods.commit_asset_upload](
        res1.batch_id,
        String(_name),
        file.fileType,
        chunks,
        "identity",
        etag.toString(),
      );
    } else if (_gch != "") {
      await actor[methods.commit_asset_upload](
        res1.batch_id,
        String(_name),
        String(_gch),
        chunks,
        "gzip",
        etag.toString(),
      );
    } else {
      await actor[methods.commit_asset_upload](
        res1.batch_id,
        String(_name),
        String(_bch),
        chunks,
        "br",
        etag.toString(),
      );
    }
  }
};
