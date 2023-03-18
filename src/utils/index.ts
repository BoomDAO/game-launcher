import clsx, { ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export * from "./auth";

export const cx = (...inputs: ClassValue[]) => twMerge(clsx(inputs));
