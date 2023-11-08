//MADE BY JACK ANTON - (ItsJackAnton in Twitter, Distrik and Discover)
//This was possible as I took a c# version as reference from the link below
//https://stackoverflow.com/questions/21750824/how-to-convert-a-string-to-a-mathematical-expression-programmatically

import Utils "../utils/Utils";

import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Deque "mo:base/Deque";
import Option "mo:base/Option";

module FormulaEvaluation {
    let specialTokens = "()^*/%+-";
    let operators = ["-", "+", "%", "/", "*", "^"];

    public func evaluate(formula : Text) : (Result.Result<Float, Text>) {

        var tokens = getTokens(formula);
        var operandStack = Deque.empty<Float>();
        var operatorStack = Deque.empty<Text>();
        var tokenIndex = 0;
        var operandCount = 0;

        label tokenLoop while(tokenIndex < tokens.size()){
            //
            var token = tokens.get(tokenIndex);

            if (token == "("){

                let subFormulaResult = getSubFormula(tokens, tokenIndex);
                switch(subFormulaResult){
                    case(#ok subFormula){
                        tokenIndex := subFormula.1;
                        let subEvaluationResult = evaluate(subFormula.0);

                        switch(subEvaluationResult){
                            case(#ok subEvaluation){

                                operandStack :=  Deque.pushFront(operandStack, subEvaluation);
                                operandCount += 1;

                            };
                            case(#err errMsg) return #err errMsg;
                        };

                        continue tokenLoop;
                    };
                    case(#err errMsg) return #err errMsg;
                };
            };

            if (token == ")"){
                return #err "Mis-matched parentheses in expression"
            };

            //
            let _operators = Buffer.fromArray<Text>(operators);

            let tokenOperatorIndex = Option.get(Utils.bufferTextIndexOf(_operators, #text token), -1);
            let isTokenAnOperator = tokenOperatorIndex >= 0;

            if(isTokenAnOperator){

                var firstOperatorStackIndex = 0;
                var firstOperatorStack = "";

                switch(Deque.peekFront(operatorStack)){
                    case (? value) firstOperatorStack := value;
                    case _ {};
                };

                switch(Utils.bufferTextIndexOf(_operators, #text firstOperatorStack)){
                    case(? value) firstOperatorStackIndex := value;
                    case _ {};
                };

                if(tokenOperatorIndex < firstOperatorStackIndex){
                    var handleOperandsAndOperatorResult = handleOperandsAndOperators(operandStack, operatorStack);
                    switch handleOperandsAndOperatorResult
                    {
                        case (#ok result){
                            operandStack := result.0;
                            operatorStack := result.1;
                        };
                        case (#err err) return #err err;
                    };
                };

                operatorStack := Deque.pushFront(operatorStack, token);
            }
            else{
                operandStack := Deque.pushFront(operandStack, Utils.textToFloat(token));
                operandCount += 1;
            };
            //
            tokenIndex += 1;
        };

        //

        var handleOperandsAndOperatorResult = handleOperandsAndOperators(operandStack, operatorStack);
        switch handleOperandsAndOperatorResult
        {
            case (#ok result){
                operandStack := result.0;
                operatorStack := result.1;
            };
            case (#err err) return #err err;
        };
        //
        switch(Deque.popFront(operandStack)){
            case (? pop){
                return #ok(pop.0);
            };
            case _ {
                return #err "Something went wrong when poping from operandStack"
            };
        };
    };
    private func getTokens(formula : Text) : (Buffer.Buffer<Text>) {
        var tokens = Buffer.Buffer<Text>(0);
        var temp = "";

        for(item in Text.toIter(formula)){

            switch(Utils.indexOf(specialTokens, item)){
                case(? index){

                    if(temp.size() > 0){
                        tokens.add(temp);
                        temp := "";
                    };
                    tokens.add(Text.fromChar(item));
                };
                case _ {
                    temp := Text.concat(temp, Text.fromChar(item));
                };
            };
        };

        if(temp.size() > 0){
            tokens.add(temp);
        };

        return tokens;
    };
    private func getSubFormula(tokens : Buffer.Buffer<Text>, startIndex : Nat) : (Result.Result<(Text,Nat),Text>){
        var temp = "";
        var parenLevels = 1;
        var currentIndex = startIndex + 1;

        while(currentIndex < tokens.size() and parenLevels > 0){

            let token = tokens.get(currentIndex);

            if (token == "(")
            {
                parenLevels += 1;
            };

            if (token == ")")
            {
                parenLevels -= 1;
            };

            if (parenLevels > 0)
            {
                temp := Text.concat(temp, token);
            };

            currentIndex += 1;
        };

        if (parenLevels > 0)
        {
            return #err "Mis-matched parentheses in expression"
        };

        return #ok (temp, currentIndex)
    };
    private func handleOperandsAndOperators(operandStack : Deque.Deque<Float>, operatorStack : Deque.Deque<Text>) : (Result.Result<(operandStack : Deque.Deque<Float>, operatorStack : Deque.Deque<Text>), Text>){

        var _operandStack = operandStack;
        var _operatorStack = operatorStack;
        
        while(Deque.isEmpty(_operatorStack) == false){
            
            var op = "";
            var arg2 = 0.0;
            var arg1 = 0.0;
            switch(Deque.popFront(_operatorStack)){
                case (? pop){
                    _operatorStack := pop.1;
                    op := pop.0;
                };
                case _ {
                    return #err "Something went wrong when poping from operatorStack"
                };
            };
            switch(Deque.popFront(_operandStack)){
                case (? pop){
                    _operandStack := pop.1;
                    arg2 := pop.0;
                };
                case _ {
                    return #err "Something went wrong when poping from operandStack"
                };
            };
            switch(Deque.popFront(_operandStack)){
                case (? pop){
                    _operandStack := pop.1;
                    arg1 := pop.0;
                };
                case _ {
                    return #err "Something went wrong when poping from operandStack"
                };
            };

            var opResult = 0.0;
            switch(op)
            {
                case("-") opResult := arg1 - arg2;
                case("+") opResult := arg1 + arg2;
                case("%") opResult := arg1 % arg2;
                case("/") opResult := arg1 / arg2;
                case("*") opResult := arg1 * arg2;
                case("^") opResult := Float.pow(arg1, arg2);
                case _ return #err "Operator mismatch";
            };
            
            _operandStack := Deque.pushFront(_operandStack, opResult);
        };

        return #ok ((_operandStack, _operatorStack));
    };
};