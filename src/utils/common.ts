import clsx, { ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export const cx = (...inputs: ClassValue[]) => twMerge(clsx(inputs));

export const convertToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const fileReader = new FileReader();
    fileReader.readAsDataURL(file);
    fileReader.onload = () => {
      resolve(String(fileReader.result));
    };
    fileReader.onerror = (error) => {
      reject(error);
    };
  });
};
