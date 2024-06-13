import React from "react";
import useWindowResize from "beautiful-react-hooks/useWindowResize";

export const useBreakpoint = () => {
  const [width, setWidth] = React.useState(window.innerWidth);
  const [height, setHeight] = React.useState(window.innerHeight);

  const onWindowResize = useWindowResize();

  onWindowResize(() => {
    setWidth(window.innerWidth);
    setHeight(window.innerHeight);
  });

  return {
    xs: width < 640,
    sm: width > 640 && width < 768,
    md: width > 768 && width < 1024,
    lg: width > 1024 && width < 1280,
    xl: width > 1280 && width < 1536,
    xxl: width > 1536,
    md_more: width > 768,
    lg_more: width > 1024,
    smallHeight: height < 750,
    width,
    height,
  };
};