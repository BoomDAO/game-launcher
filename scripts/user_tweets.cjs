const needle = require('needle');
require('dotenv').config();
const userId = "1015217558163636224";
const url = `https://api.twitter.com/2/users/${userId}/tweets`;
const bearerToken = process.env.BEARER_TOKEN;

const getUserTweets = async () => {
    let userTweets = [];
    let params = {
        // "max_results": 5,
        "tweet.fields": "created_at",
        "expansions": "author_id"
    }

    const options = {
        headers: {
            "User-Agent": "v2UserTweetsJS",
            "authorization": `Bearer ${bearerToken}`
        }
    }

    // let hasNextPage = true;
    // let nextToken = null;
    // let userName;
    // console.log("Retrieving Tweets...");

    // while (hasNextPage) {
        // let resp = await getPage(params, options, nextToken);
    //     if (resp && resp.meta && resp.meta.result_count && resp.meta.result_count > 0) {
    //         userName = resp.includes.users[0].username;
    //         if (resp.data) {
    //             userTweets.push.apply(userTweets, resp.data);
    //         }
    //         if (resp.meta.next_token) {
    //             nextToken = resp.meta.next_token;
    //         } else {
    //             hasNextPage = false;
    //         }
    //     } else {
    //         hasNextPage = false;
    //     }
    // }
    const resp = await needle('get', url, params, options);
    console.log(resp.body.data[0]);

    // console.dir(userTweets, {
    //     depth: null
    // });
    // console.log(`Got ${userTweets.length} Tweets from ${userName} (user ID ${userId})!`);

}

// const getPage = async (params, options, nextToken) => {
//     if (nextToken) {
//         params.pagination_token = nextToken;
//     }
//     try {
//         const resp = await needle('get', url, params, options);

//         if (resp.statusCode != 200) {
//             console.log("here")
//             console.log(`${resp.statusCode} ${resp.statusMessage}:\n${resp.body}`);
//             return;
//         }
//         return resp.body;
//     } catch (err) {
//         throw new Error(`Request failed: ${err}`);
//     }
// }

getUserTweets();