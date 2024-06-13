const needle = require('needle');
require('dotenv').config();
const token = process.env.BEARER_TOKEN;

const endpointURL = "https://api.twitter.com/2/users/by?usernames="

async function getRequest() {
    const params = {
        usernames: "boomdaosns,HiteshTripath1,tommyinvests,icpmaximalist",
        "user.fields": "created_at,name,connection_status,public_metrics"
        // "expansions": "pinned_tweet_id"
    }
    const res = await needle('get', endpointURL, params, {
        headers: {
            "User-Agent": "v2UserLookupJS",
            "authorization": `Bearer ${token}`
        }
    })
    if (res.body) {
        return res.body;
    } else {
        throw new Error('Unsuccessful request')
    }
}

(async () => {
    try {
        const response = await getRequest();
        console.dir(response, {
            depth: null
        });
    } catch (e) {
        console.log(e);
        process.exit(-1);
    }
    process.exit();
})();