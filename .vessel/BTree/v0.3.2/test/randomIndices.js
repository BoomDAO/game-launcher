var fs = require("fs");

function shuffle(array) {

  let currentIndex = array.length,  randomIndex;

  // While there remain elements to shuffle.
  while (currentIndex != 0) {

    // Pick a remaining element.
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex--;

    // And swap it with the current element.
    [array[currentIndex], array[randomIndex]] = [
      array[randomIndex], array[currentIndex]];
  }

  return array;
}

var arr3000 = [...Array(3000).keys()]
shuffle(arr3000);

fs.writeFileSync(
  "rand3000.mo",
  `module {\n  public let rand3000 = ${JSON.stringify(arr3000)};\n}`,
  function (err) {
    if (err) { console.error("error writing random array to file") }
  }
);