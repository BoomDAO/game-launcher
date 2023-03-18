import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "@/context/authContext";
import { navPaths } from "@/shared";

interface ProtectedRouteProps {
  redirectPath?: string;
}

const ProtectedRoute = ({
  redirectPath = navPaths.home,
}: ProtectedRouteProps) => {
  const { session, isLoading } = useAuth();

  console.log("isLoading", isLoading);

  if (isLoading) return null;

  if (!session) return <Navigate to={redirectPath} replace />;

  return <Outlet />;
};

export default ProtectedRoute;
