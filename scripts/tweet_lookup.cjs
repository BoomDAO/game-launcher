const needle = require('needle');
require('dotenv').config();

const token = process.env.BEARER_TOKEN;

const endpointURL = "https://api.twitter.com/2/tweets?ids=";

async function getRequest() {
    const params = {
        "ids": "1786701436769669580", 
        "tweet.fields": "lang,author_id", 
        "user.fields": "created_at" 
    }
    const res = await needle('get', endpointURL, params, {
        headers: {
            "User-Agent": "v2TweetLookupJS",
            "authorization": `Bearer ${token}`
        }
    })

    if (res.body) {
        return res.body;
    } else {
        throw new Error('Unsuccessful request');
    }
}

(async () => {

    try {
        const response = await getRequest();
        console.log(response);
    } catch (e) {
        console.log(e);
        process.exit(-1);
    }
    process.exit();
})();