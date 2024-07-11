import axios from 'axios';
import ENV from "../../../env.json"
import React from "react";
import defaultTexts from "../api/defaultTexts.json";

type Texts = typeof defaultTexts;
const IPSTACK_API_KEY = ENV.IPSTACK_API_KEY;
interface GeoInfo {
    isBlocked: boolean;
    ip: string;
    country_name: string;
    country_code: string;
}
interface GeoContext {
    isLoading: boolean;
    geoInfo: GeoInfo | null;
    geoBlockedWarning: string;
    getGeoInfo: (ip: string) => Promise<GeoInfo>;
}

export const GeoContext = React.createContext({} as GeoContext);

export const GeoContextProvider = ({ children }: React.PropsWithChildren) => {
    const [isLoading, setIsLoading] = React.useState(true);
    const [geoInfo, setGeoInfo] = React.useState<GeoInfo | null>(null);
    const [geoBlockedWarning, setGeoBlockedWarning] = React.useState<string>("");

    const checkGeoInfo = async () => {
        try {
            let isUserBlocked = false;
            const github = "https://raw.githubusercontent.com/BoomDAO/gaming-guild-content/main";
            const info = await fetch(`${github}/texts.json`);
            const texts = (await info.json()) as Texts;
            const blocked_country_codes: string[] = [];
            texts.blocked_country_info.codes.map((t) => {
                blocked_country_codes.push(t);
            });
            const geo_blocking_info = texts.blocked_country_info.geo_blocking_info;
            const response = await axios.get(ENV.FETCH_GEO_INFO_URL);
            console.log(response);
            let user_country_code = response.data.country_code;
            for (let i = 0; i < blocked_country_codes.length; i += 1) {
                if (user_country_code == blocked_country_codes[i]) {
                    isUserBlocked = true;
                    break;
                }
            };
            let geo_info: GeoInfo = {
                isBlocked: isUserBlocked,
                ip: response.data.ip,
                country_name: response.data.country_name,
                country_code: response.data.country_code,
            };
            setGeoInfo(geo_info);
            setGeoBlockedWarning(geo_blocking_info);
        } catch (error) {
            console.log("err while checking geo info", error);
            setGeoInfo(null);
        } finally {
            setIsLoading(false);
        };
    };

    React.useEffect(() => {
        checkGeoInfo();
    }, []);

    const getGeoInfo = async (ip: string) => {
        try {
            const response = await axios.get(`http://api.ipstack.com/${ip}?access_key=${IPSTACK_API_KEY}`);
            console.log(response.data);
            return response.data;
        } catch (error) {
            throw new Error('Error fetching geo information');
        }
    }

    const value = {
        isLoading,
        geoInfo,
        getGeoInfo,
        geoBlockedWarning,
    };

    return <GeoContext.Provider value={value}>{children}</GeoContext.Provider>;
};

export const useGeoContext = () => React.useContext(GeoContext);
