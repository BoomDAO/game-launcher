import { Route, Routes } from "react-router-dom";
import Layout from "@/components/Layout";
import ProtectedRoute from "@/components/ProtectedRoute";
import { AuthContextProvider } from "@/context/authContext";
import { navPaths } from "@/shared";
import Toast from "./components/ui/Toast";
import { GlobalContextProvider } from "./context/globalContext";
import { ThemeContextProvider } from "./context/themeContext";
import Home from "./pages/Home";
import NotFound from "./pages/NotFound";
import UploadGames from "./pages/UploadGames";
import CreateGame from "./pages/UploadGames/CreateGame";
import UpdateGame from "./pages/UploadGames/UpdateGame";

function App() {
  return (
    <GlobalContextProvider>
      <AuthContextProvider>
        <ThemeContextProvider>
          <Layout>
            <Toast />
            <Routes>
              <Route path={navPaths.home} element={<Home />} />

              <Route element={<ProtectedRoute />}>
                <Route path={navPaths.upload_games} element={<UploadGames />} />
                <Route
                  path={`${navPaths.upload_games}/create_game`}
                  element={<CreateGame />}
                />
                <Route
                  path={`${navPaths.upload_games}/:canisterId`}
                  element={<UpdateGame />}
                />
                {/* <Route path={navPaths.manage_nfts} element={<ManageNfts />} />
              <Route
                path={`${navPaths.manage_nfts}/new`}
                element={<ManageNftsNew />}
              />
              <Route
                path={`${navPaths.manage_nfts}/:canisterId`}
                element={<ManageNftsUpdate />}
              />
              <Route
                path={navPaths.manage_payments}
                element={<ManagePayments />}
              /> */}
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
