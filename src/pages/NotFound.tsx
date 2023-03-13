import Button from "@/components/Button";
import React from "react";
import { NavLink } from "react-router-dom";

const NotFound = () => {
  return (
    <div className="text-center">
      <p className="text-3xl font-semibold gradient-text">404</p>
      <h1 className="mt-4 text-3xl font-bold tracking-tight text-gray-900 sm:text-5xl">
        Are you lost?
      </h1>
      <p className="mt-6 leading-7">
        Sorry, we couldn’t find the page you’re looking for.
      </p>
      <div className="mt-10 flex items-center justify-center">
        <NavLink to="/">
          <Button>Go back home</Button>
        </NavLink>
      </div>
    </div>
  );
};

export default NotFound;
