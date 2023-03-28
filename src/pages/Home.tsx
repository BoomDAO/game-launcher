import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { useGetGames } from "@/api/games";
import Card from "@/components/Card";
import Space from "@/components/ui/Space";

const data = Array.from({ length: 9 }).map((_, i) => ({
  title: `Game 0${i}`,
  image: "/banner.png",
  platform: "Browser",
  canisterId: `r44we3-pqaaa-aaaap-aaosq-cai${i}`,
}));

const Home = () => {
  const { data: games = [] } = useGetGames();

  console.log("games", games);

  return (
    <>
      <img
        src="/banner.png"
        alt="banner"
        className="h-96 w-full rounded-primary object-cover shadow"
      />

      <Space />

      <h1 className="flex flex-wrap gap-3 text-[56px] font-semibold leading-none">
        <span className="gradient-text">Games</span>
        <span>hosted in</span>
        <span className="gradient-text">smart contract canisters</span>
        <span>on the</span>
        <span className="gradient-text">ICP</span>
        <span>blockchain</span>
      </h1>

      <Space size="medium" />

      <div className="grid gap-6 grid-auto-fit-xl">
        {games.map(({ canister_id, platform, name, url, image }) => (
          <Card
            key={canister_id}
            icon={<ArrowUpRightIcon />}
            image={image}
            title={name}
            canisterId={canister_id}
            platform={platform}
            onClick={() => window.open(url, "_blank")}
          />
        ))}
      </div>
    </>
  );
};

export default Home;
