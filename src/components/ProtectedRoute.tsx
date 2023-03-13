import { useAuth } from "@/context/authContext";
import { Navigate, Outlet } from "react-router-dom";

interface ProtectedRouteProps {
  redirectPath?: string;
}

const ProtectedRoute = ({ redirectPath = "/" }: ProtectedRouteProps) => {
  const { session } = useAuth();

  if (!session) return <Navigate to={redirectPath} replace />;

  return <Outlet />;
};

export default ProtectedRoute;
