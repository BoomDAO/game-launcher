const needle = require('needle');
require('dotenv').config();
const token = process.env.BEARER_TOKEN;

const endpointUrl = "https://api.twitter.com/2/tweets/search/recent";

async function getRequest() {
    const params = {
        'query': 'conversation_id:1786701436769669580',
        'tweet.fields': 'author_id'
    }
    const res = await needle('get', endpointUrl, params, {
        headers: {
            "User-Agent": "v2RecentSearchJS",
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
        // console.dir(response, {
        //     depth: null
        // });
        console.log(response);
    } catch (e) {
        console.log(e);
        process.exit(-1);
    }
    process.exit();
})();