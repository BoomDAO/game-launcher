import { AuthContextProvider } from "@/context/authContext";
import Layout from "@/components/Layout";
import { Route, Routes } from "react-router-dom";
import ProtectedRoute from "@/components/ProtectedRoute";
import Home from "./pages/Home";
import UploadGame from "./pages/UploadGame";
import NotFound from "./pages/NotFound";

function App() {
  return (
    <AuthContextProvider>
      <Layout>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="*" element={<NotFound />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/upload-game" element={<UploadGame />} />
          </Route>
        </Routes>
      </Layout>
    </AuthContextProvider>
  );
}

export default App;
