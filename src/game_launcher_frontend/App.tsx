import { Route, Routes } from "react-router-dom";
import Layout from "@/components/Layout";
import ProtectedRoute from "@/components/ProtectedRoute";
import { AuthContextProvider } from "@/context/authContext";
import { navPaths } from "@/shared";
import Toast from "./components/ui/Toast";
import { GlobalContextProvider } from "./context/globalContext";
import { ThemeContextProvider } from "./context/themeContext";
import Home from "./pages/Home";
import ManageNfts from "./pages/ManageNfts";
import CreateCollection from "./pages/ManageNfts/CreateCollection";
import UpdateCollection from "./pages/ManageNfts/UpdateCollection";
import NotFound from "./pages/NotFound";
import UploadGames from "./pages/UploadGames";
import CreateGame from "./pages/UploadGames/CreateGame";
import UpdateGame from "./pages/UploadGames/Games/UpdateGame";
import TokenDeployer from "./pages/TokenDeployer";
import WorldDeployer from "./pages/WorldDeployer";
import CreateWorld from "./pages/WorldDeployer/CreateWorld"
import DeployToken from "./pages/TokenDeployer/DeployToken";
import Token from "./pages/TokenDeployer/Token/Token";
import Game from "./pages/UploadGames/Games/Game";
import ManageWorlds from "./pages/WorldDeployer/ManageWorlds";
import Guilds from "./pages/GamingGuilds";
import VerifyPage from "./pages/GamingGuilds/VerifyOtpPage";
import EmailPage from "./pages/GamingGuilds/EmailPage";
import VerifyOtpPage from "./pages/GamingGuilds/VerifyOtpPage";
import VerifyEmailPage from "./pages/GamingGuilds/VerifyEmailPage";

function App() {
  return (
    <GlobalContextProvider>
      <AuthContextProvider>
        <ThemeContextProvider>
          <Layout>
            <Toast />
            <Routes>
              <Route path={navPaths.home} element={<Home />} />
              <Route
                path={`${navPaths.gaming_guilds}`}
                element={<Guilds />}
              />

              <Route element={<ProtectedRoute />}>
                <Route path={navPaths.upload_games} element={<UploadGames />} />
                <Route
                  path={`${navPaths.upload_games_new}`}
                  element={<CreateGame />}
                />
                <Route
                  path={`${navPaths.upload_games}/:canisterId`}
                  element={<Game />}
                />
                <Route path={navPaths.manage_nfts} element={<ManageNfts />} />
                <Route
                  path={`${navPaths.manage_nfts_new}`}
                  element={<CreateCollection />}
                />
                <Route
                  path={`${navPaths.manage_nfts}/:canisterId`}
                  element={<UpdateCollection />}
                />
                <Route
                  path={`${navPaths.token_deployer}`}
                  element={<TokenDeployer />}
                />
                <Route
                  path={`${navPaths.deploy_new_token}`}
                  element={<DeployToken />}
                />
                <Route
                  path={`${navPaths.token}/:canisterId`}
                  element={<Token />}
                />
                <Route
                  path={`${navPaths.world_deployer}`}
                  element={<WorldDeployer />}
                />
                <Route
                  path={`${navPaths.world_deployer}/:canisterId`}
                  element={<CreateWorld />}
                />
                <Route
                  path={`${navPaths.manage_worlds}/:canisterId`}
                  element={<ManageWorlds />}
                />
                <Route
                  path={`${navPaths.gaming_guilds_verification}/:email`}
                  element={<VerifyOtpPage />}
                />
                <Route
                  path={`${navPaths.gaming_guilds_verification}`}
                  element={<VerifyEmailPage />}
                />
              </Route>

              <Route path="*" element={<NotFound />} />
            </Routes>
          </Layout>
        </ThemeContextProvider>
      </AuthContextProvider>
    </GlobalContextProvider>
  );
}

export default App;
