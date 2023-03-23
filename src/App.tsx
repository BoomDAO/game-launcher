import { Route, Routes } from "react-router-dom";
import Layout from "@/components/Layout";
import ProtectedRoute from "@/components/ProtectedRoute";
import { AuthContextProvider } from "@/context/authContext";
import { navPaths } from "@/shared";
import { ThemeContextProvider } from "./context/themeContext";
import Home from "./pages/Home";
import ManageNfts from "./pages/ManageNfts";
import ManageNftsNew from "./pages/ManageNftsNew";
import ManageNftsUpdate from "./pages/ManageNftsUpdate";
import ManagePayments from "./pages/ManagePayments";
import NotFound from "./pages/NotFound";
import UploadGames from "./pages/UploadGames";
import UploadUpdateGame from "./pages/UploadUpdateGame";

function App() {
  return (
    <AuthContextProvider>
      <ThemeContextProvider>
        <Layout>
          <Routes>
            <Route path={navPaths.home} element={<Home />} />

            <Route element={<ProtectedRoute />}>
              <Route path={navPaths.upload_games} element={<UploadGames />} />
              <Route
                path={`${navPaths.upload_games}/:canisterId`}
                element={<UploadUpdateGame />}
              />
              <Route path={navPaths.manage_nfts} element={<ManageNfts />} />
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
              />
            </Route>

            <Route path="*" element={<NotFound />} />
          </Routes>
        </Layout>
      </ThemeContextProvider>
    </AuthContextProvider>
  );
}

export default App;
