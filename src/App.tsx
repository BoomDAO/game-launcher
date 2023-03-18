import { Route, Routes } from "react-router-dom";
import Layout from "@/components/Layout";
import ProtectedRoute from "@/components/ProtectedRoute";
import { AuthContextProvider } from "@/context/authContext";
import { ThemeContextProvider } from "./context/themeContext";
import Home from "./pages/Home";
import ManageNfts from "./pages/ManageNfts";
import ManagePayments from "./pages/ManagePayments";
import NotFound from "./pages/NotFound";
import UploadGames from "./pages/UploadGames";
import { navPaths } from "./shared";

function App() {
  return (
    <AuthContextProvider>
      <ThemeContextProvider>
        <Layout>
          <Routes>
            <Route path={navPaths.home} element={<Home />} />

            <Route element={<ProtectedRoute />}>
              <Route path={navPaths.upload_games} element={<UploadGames />} />
              <Route path={navPaths.manage_nfts} element={<ManageNfts />} />
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
