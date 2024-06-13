const needle = require('needle');
require('dotenv').config();
const tweetId = '1786701436769669580';
const url = `https://api.twitter.com/2/tweets/${tweetId}/quote_tweets`;
const bearerToken = process.env.BEARER_TOKEN;
const getQuoteTweets = async () => {
    let quoteTweets = [];
    let params = {
        "max_results": 100,
        "tweet.fields": "created_at"
    }
    const options = {
        headers: {
            "User-Agent": "v2QuoteTweetsJS",
            "authorization": `Bearer ${bearerToken}`
        }
    }
    let hasNextPage = true;
    let nextToken = null;
    while (hasNextPage) {
        let resp = await getPage(params, options, nextToken);
        if (resp && resp.meta && resp.meta.result_count && resp.meta.result_count > 0) {
            if (resp.data) {
                quoteTweets.push.apply(quoteTweets, resp.data);
            }
            if (resp.meta.next_token) {
                nextToken = resp.meta.next_token;
            } else {
                hasNextPage = false;
            }
        } else {
            hasNextPage = false;
        }
    }
    console.dir(quoteTweets, {
        depth: null
    });
    console.log(`Got ${quoteTweets.length} quote Tweets for Tweet ID ${tweetId}!`);
}

const getPage = async (params, options, nextToken) => {
    if (nextToken) {
        params.pagination_token = nextToken;
    }
    try {
        const resp = await needle('get', url, params, options);
        if (resp.statusCode != 200) {
            console.log(`${resp.statusCode} ${resp.statusMessage}:\n${resp.body}`);
            return;
        }
        return resp.body;
    } catch (err) {
        throw new Error(`Request failed: ${err}`);
    }
}

getQuoteTweets();