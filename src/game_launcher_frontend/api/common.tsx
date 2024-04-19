import { useQuery } from "@tanstack/react-query";
import defaultTexts from "./defaultTexts.json";

type Texts = typeof defaultTexts;
export const queryKeys = {
    texts: "texts",
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
    console.log(data);
    if (data) return { data: data, ...rest };
    return { data: defaultTexts, ...rest };
};