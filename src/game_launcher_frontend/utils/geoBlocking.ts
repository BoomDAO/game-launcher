import { getGeoInfo } from "@/context/geoContext";
const BLOCKED_COUNTRIES = ['US', 'IND']; // Replace with actual country names or codes

async function shouldBlockIP(ip: string): Promise<boolean> {
    try {
        const geoInfo = await getGeoInfo(ip);
        if (BLOCKED_COUNTRIES.includes(geoInfo.country_name)) {
            return true;
        }
        return false;
    } catch (error) {
        console.error(error);
        return false;
    }
}

export { shouldBlockIP };
