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
