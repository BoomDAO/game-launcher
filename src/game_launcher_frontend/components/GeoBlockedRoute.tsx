import { Navigate, Outlet } from "react-router-dom";
import React from "react";
import { navPaths } from "@/shared";
import axios from 'axios';
import ENV from "../../../env.json"
import defaultTexts from "../api/defaultTexts.json";

type Texts = typeof defaultTexts;
const IPSTACK_API_KEY = ENV.IPSTACK_API_KEY;

interface GeoBlockedRouteProps {
  redirectPath?: string;
}

const GeoBlockedRoute = ({
  redirectPath = navPaths.launchpad,
}: GeoBlockedRouteProps) => {
  const [isUserBlocked, setIsUserBlocked] = React.useState(false);
  const [loading, setLoading] = React.useState(false);
  React.useEffect(() => {
    const checkGeoBlocking = async () => {
      setLoading(true);
      let isUserBlocked = false;
      const github = "https://raw.githubusercontent.com/BoomDAO/gaming-guild-content/main";
      const info = await fetch(`${github}/texts.json`);
      const texts = (await info.json()) as Texts;
      const blocked_country_codes: string[] = [];
      texts.blocked_country_info.codes.map((t) => {
        blocked_country_codes.push(t);
      });
      const response = await axios.get(ENV.FETCH_GEO_INFO_URL);
      let user_country_code = response.data.country_code;
      for (let i = 0; i < blocked_country_codes.length; i += 1) {
        if (user_country_code == blocked_country_codes[i]) {
          isUserBlocked = true;
          break;
        }
      };
      setLoading(false);
      setIsUserBlocked(isUserBlocked);
    };
    checkGeoBlocking();
  }, []);
  if (loading) return null;
  if (isUserBlocked) return <Navigate to={redirectPath} replace />;
  return <Outlet />;
};

export default GeoBlockedRoute;
