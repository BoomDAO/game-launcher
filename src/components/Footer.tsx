import Divider from "./ui/Divider";

const Footer = () => {
  return (
    <>
      <Divider className="mb-6" />
      <div className="flex justify-between">
        <p>COPYRIGHT © 2023 PLETHORA GAME PLATFORM. ALL RIGHTS RESERVED</p>
        <div className="flex items-center gap-4">
          <p className="gradient-text text-lg font-semibold">Follow us:</p>
          <div className="flex gap-3">
            <img src="/twitter.svg" alt="twitter" className="cursor-pointer" />
            <img src="/medium.svg" alt="medium" className="cursor-pointer" />
          </div>
        </div>
      </div>
    </>
  );
};

export default Footer;
