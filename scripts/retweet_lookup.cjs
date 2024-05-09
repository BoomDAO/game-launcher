const needle = require("needle");
require('dotenv').config();
const token = process.env.BEARER_TOKEN;
const id = "1786701436769669580";
const endpointURL = `https://api.twitter.com/2/tweets/${id}/retweeted_by`;

async function getRequest() {
  const params = {
    "tweet.fields": "lang,author_id", 
    "user.fields": "created_at", 
  };
  const res = await needle("get", endpointURL, params, {
    headers: {
      "User-Agent": "v2RetweetedByUsersJS",
      authorization: `Bearer ${token}`
    },
  });

  if (res.body) {
    return res.body;
  } else {
    throw new Error("Unsuccessful request");
  }
}

(async () => {
  try {
    const response = await getRequest();
    console.log(response);
    // console.dir(response, {
    //   depth: null,
    // });
  } catch (e) {
    console.log(e);
    process.exit(-1);
  }
  process.exit();
})();