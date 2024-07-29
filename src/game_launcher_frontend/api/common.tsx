import { useQuery } from "@tanstack/react-query";
import defaultTexts from "./defaultTexts.json";
import defaultTwitterTexts from "./defaultTwitterText.json";

type Texts = typeof defaultTexts;
type twitterTexts = typeof defaultTwitterTexts;
export const queryKeys = {
    texts: "texts",
    twitter_texts: "twitter_texts"
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

export const useGetTwitterTexts = () => {
    const { data, ...rest } = useQuery({
        queryKey: [queryKeys.twitter_texts],
        queryFn: async () => {
            const res = await fetch(`${github}/twitter_content.json`);
            const texts = (await res.json()) as twitterTexts;
            return texts as twitterTexts;
        },
    });
    if (data) return { data: data, ...rest };
    return { data: defaultTwitterTexts, ...rest };
};