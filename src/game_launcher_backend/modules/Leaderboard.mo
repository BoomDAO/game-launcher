import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Utils "../utils/Utils";

module Leaderboard {
    public type Entry = {
        user_principal : Text;
        score : Int;
    };

    public class Leaderboard(cap : Nat) {
        var top_users = Buffer.Buffer<Text>(cap);
        var users_score_mapping : Trie.Trie<Text, Nat> = Trie.empty();
        let capacity : Nat = cap;

        public func getScore(user_principal : Text) : Nat {
            switch (Trie.find(users_score_mapping, Utils.keyT(user_principal), Text.equal)) { //Trie.find(users_score_mapping, Utils.keyT(user_principal), Text.equal)
                case (?score) {
                    return score;
                };
                case _ {
                    return 0;
                };
            };
        };

        public func increamentScore(user_principal : Text, amount : Nat) {
            var current_score : Nat = getScore(user_principal);

            let new_score = current_score + amount;
            users_score_mapping := Trie.put(users_score_mapping, Utils.keyT(user_principal), Text.equal, new_score).0;

            //Do logic to locate user among top users
            locateUser_(user_principal, new_score);
        };

        private func locateUser_(user_principal : Text, new_score : Nat) {
            var index: Nat = 0;

            //If by any chance u are already in top x remove yourself
            var cache_principal = user_principal;
            var self_found = false;
            label try_remove_self_loop for (top_user in top_users.vals()){
                if(top_user == user_principal){
                    var a = top_users.remove(index);
                    break try_remove_self_loop;
                };

                index += 1;
            };

            //Find lowest score
            index := 0;
            var lowest_score = 1_000_000_000_000;
            var lowest_score_index = 0;
            var lowest_found = false;

            for (top_user in top_users.vals()) {
                let top_user_score = getScore(top_user);

                if(lowest_score > top_user_score){
                    lowest_score := top_user_score;
                    lowest_score_index := index;
                    lowest_found := true;
                };
                index += 1;
            };

            //then try readd yourself
            if(lowest_found){
                if(top_users.size() < capacity){
                    top_users.add(user_principal);
                }else{
                    if(lowest_score <= new_score) 
                    {
                        top_users.put(lowest_score_index, user_principal);
                    }
                }
            }
            else{
                if(top_users.size() < capacity){
                    top_users.add(user_principal);
                }
            }
        };

        public func getTopUsersAndScores() : Buffer.Buffer<Entry> {

            var top_users_and_scores = Buffer.Buffer<Entry>(top_users.size());

            var index = 0;
            let top_users_vals = top_users.vals();
            for (top_user in top_users_vals) {
                let top_user_score = getScore(top_user);
                var entry : Entry = { user_principal = top_user; score = top_user_score;};

                top_users_and_scores.add(entry);
                index += 1;
            };
            return top_users_and_scores;
        };

        public func dispose() : (){
            top_users := Buffer.Buffer<Text>(cap);
            users_score_mapping := Trie.empty();
        };
    };
}