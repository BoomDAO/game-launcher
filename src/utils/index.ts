import clsx, { ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export * from "./auth";
export * from "./boundary";

export const cx = (...inputs: ClassValue[]) => twMerge(clsx(inputs));
