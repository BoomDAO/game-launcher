const EmptyGameCard = ({ length = 0 }) => {
  return (
    <>
      {length === 1 && (
        <>
          <div />
          <div />
        </>
      )}
      {length === 2 && <div />}
    </>
  );
};

export default EmptyGameCard;
