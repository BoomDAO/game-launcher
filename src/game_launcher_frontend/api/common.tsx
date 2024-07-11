import { useQuery } from "@tanstack/react-query";
import defaultTexts from "./defaultTexts.json";

type Texts = typeof defaultTexts;
export const queryKeys = {
    texts: "texts",
    country_codes: "country_codes"
};

const github =
    "https://raw.githubusercontent.com/BoomDAO/gaming-guild-content/main";

export const useGetTexts = () => {
    const { data, ...rest } = useQuery({
        queryKey: [queryKeys.texts],
        queryFn: async () => {
            const res = await fetch(`${github}/texts.json`);
            const texts = (await res.json()) as Texts;

            const titleSequence: (string | number)[] = [];

            texts.home.title.map((t) => {
                titleSequence.push(t);
                titleSequence.push(1000);
            });

            return {
                ...texts,
                home: { ...texts.home, title_sequence: titleSequence },
            } as Texts;
        },
    });
    if (data) return { data: data, ...rest };
    return { data: defaultTexts, ...rest };
};

export const useGetGeoBlockedCodes = () => {
    const { data, ...rest } = useQuery({
        queryKey: [queryKeys.texts],
        queryFn: async () => {
            const res = await fetch(`${github}/texts.json`);
            const texts = (await res.json()) as Texts;

            const blocked_country_codes : string[] = [];

            texts.blocked_country_info.codes.map((t) => {
                blocked_country_codes.push(t);
            });

            return {
                ...texts,
                blocked_country_info: { ...texts.blocked_country_info, codes: blocked_country_codes },
            } as Texts;
        },
    });
    if (data) return { data: data, ...rest };
    return { data: defaultTexts, ...rest };
};