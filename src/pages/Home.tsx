import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import Card from "@/components/Card";

const data = Array.from({ length: 9 }).map((_, i) => ({
  title: `Game 0${i}`,
  image: "/banner.png",
  platform: "Browser",
  canisterId: `r44we3-pqaaa-aaaap-aaosq-cai${i}`,
}));

const Home = () => {
  return (
    <>
      <img
        src="/banner.png"
        alt="banner"
        className="h-96 w-full rounded-card object-cover shadow"
      />

      <h1 className="flex flex-wrap gap-3 pt-8 pb-16 text-[56px] font-semibold leading-none">
        <span className="gradient-text">Games</span>
        <span>hosted in</span>
        <span className="gradient-text">smart contract canisters</span>
        <span>on the</span>
        <span className="gradient-text">ICP</span>
        <span>blockchain</span>
      </h1>

      <div className="grid gap-6 grid-auto-fit-xl">
        {data.map(({ canisterId, image, platform, title }) => (
          <Card
            key={canisterId}
            icon={<ArrowUpRightIcon />}
            image={image}
            title={title}
            canisterId={canisterId}
            platform={platform}
          />
        ))}
      </div>
    </>
  );
};

export default Home;
