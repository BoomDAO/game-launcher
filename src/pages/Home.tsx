const Home = () => {
  return (
    <div>
      <img
        src="/banner.png"
        alt="banner"
        className="h-96 w-full rounded-card object-cover"
      />

      <h1 className="my-6 flex flex-wrap gap-3 text-[56px] font-semibold leading-none">
        <span className="gradient-text">Games</span>
        <span>hosted in</span>
        <span className="gradient-text">smart contract canisters</span>
        <span>on the</span>
        <span className="gradient-text">ICP</span>
        <span>blockchain</span>
      </h1>
    </div>
  );
};

export default Home;
