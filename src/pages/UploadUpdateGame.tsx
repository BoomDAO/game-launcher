import React from "react";
import { useParams } from "react-router-dom";

const UploadUpdateGame = () => {
  const { canisterId } = useParams();
  return <div>{canisterId}</div>;
};

export default UploadUpdateGame;
