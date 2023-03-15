import { Route, Routes } from "react-router-dom";
import Layout from "@/components/Layout";
import ProtectedRoute from "@/components/ProtectedRoute";
import { AuthContextProvider } from "@/context/authContext";
import { ThemeContextProvider } from "./context/themeContext";
import Home from "./pages/Home";
import NotFound from "./pages/NotFound";
import UploadGame from "./pages/UploadGame";

function App() {
  return (
    <AuthContextProvider>
      <ThemeContextProvider>
        <Layout>
          <Routes>
            <Route path="/" element={<Home />} />

            <Route element={<ProtectedRoute />}>
              <Route path="/upload-game" element={<UploadGame />} />
            </Route>

            <Route path="*" element={<NotFound />} />
          </Routes>
        </Layout>
      </ThemeContextProvider>
    </AuthContextProvider>
  );
}

export default App;
