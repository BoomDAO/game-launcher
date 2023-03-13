import { NavLink } from "react-router-dom";
import Button from "./Button";

const Navigation = () => {
  const paths = [
    {
      name: "Browse games",
      path: "/",
    },
    {
      name: "Upload Games",
      path: "/upload-games",
    },
    {
      name: "Manage NFTs",
      path: "/manage-nfts",
    },
    {
      name: "Manage Payments",
      path: "/manage-payments",
    },
  ];

  return (
    <div className="flex items-center justify-between">
      <img src="/logo.png" width={164} alt="logo" />

      <nav className="space-x-4 uppercase text-sm">
        {paths.map(({ name, path }) => (
          <NavLink
            key={name}
            className={({ isActive }) => (isActive ? "gradient-text" : "")}
            to={path}
          >
            {name}
          </NavLink>
        ))}
      </nav>

      <Button rightArrow>Login</Button>
    </div>
  );
};

export default Navigation;
