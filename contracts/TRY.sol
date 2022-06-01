// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "contracts/TryKitty.sol";

/**
 * @title TRY
 * @dev TRY Lottery
 */
contract TRY {

    address payable operator; //lottery operator
    //modifier
    modifier onlyOperator {
        require(msg.sender == operator, "only the lottery operator can use this function");
        _;
    }
    //withdraw the funds of the contract
    function withdraw(address withdrawal) private onlyOperator isRoundFinished{
       payable(withdrawal).transfer(address(this).balance);
        emit Log("the total balance of the contract has been transferred", operator);

    }

    uint[] luckyNumbers; //TODO: va ripulito controllare in test

    uint blockNumber; //initial round block number
    uint constant M = 150; //lottery fixed duration 30 mins
    uint constant K = 42; //fixed parameter K
    //uint constant D = 10; //10 blocks represent 2 minutes delay, ---> controlla la sua necessità
    uint constant TKT_PRICE = 200000 gwei; //ticket price
    uint roundTime;

    bool arePrizesAwarded;

    TryKitty tryNft; //prize

    //struct that represents a Ticket of the gambler
    struct Ticket {
        address gambler;
        uint[] numbers;
        uint powerball;
        uint matchesN;
        bool matchesPb;
        bool isLucky;
    }

    //array of all bets
    Ticket[] bets;

    enum roundPhase{ Active, Closed, Finished }
    roundPhase phase;

    enum lotteryState{ Active, Closed }
    lotteryState state;

    //event to log round phase and lottery state
    event LotteryStateChanged(string eventLog, lotteryState newState);
    event RoundPhaseChanged(string eventLog, roundPhase newPhase);
    
    //to ensure the current phase of the round is the correct one
    modifier isRoundFinished() {
        require(phase == roundPhase.Finished, "The round has not yet Finished");
        _;
    }

    modifier isRoundActive() {
        require(phase == roundPhase.Active, "The Round is over, come back next time");
        _;
    }

    modifier isRoundClosed() {
        require(phase == roundPhase.Closed, "the Round has not yet Closed");
        _;
    }

    //to ensure the current state of the contract is the correct one
    modifier isLotteryActive() {
        require(state == lotteryState.Active, "Lottery has been closed by the lottery operator");
        _;
    }
    //function that change the lottery state
    function changeLotteryState(lotteryState _newState) private {
		state = _newState;
        if(_newState == lotteryState.Active)
		    emit LotteryStateChanged("The Lottery has been activated", state);
        else
            emit LotteryStateChanged("The Lottery has been closed", state);
	}
    //function that change the lottery state
    function changePhaseRound(roundPhase _newPhase) private {
		phase = _newPhase;
        if(_newPhase == roundPhase.Active)
		    emit RoundPhaseChanged("The Round has been activated", phase);
        else if(_newPhase == roundPhase.Closed)
            emit RoundPhaseChanged("The Round has been closed", phase);
        else
            emit RoundPhaseChanged("The Round is Finished", phase);
	}


    //useful event to log what happen
    event Log(string eventLog, address caller);
    event prizeAwarded(string eventLog, address winner, uint classPrize);
        

    constructor() {

        operator = payable(msg.sender);        
        arePrizesAwarded = false;
        tryNft = new TryKitty();

        //activate the lottery and the round
        changeLotteryState(lotteryState.Active);
        //changePhaseRound(roundPhase.Active); meglio chiamare start New ROund TODO !! attivare il round qui??
        //generates the first 8 prizes, one for each class
        for (uint i = 0; i<=8; i++) {
            //mint initial prizes, one of each class
            mint(i+1);
        }
    }

    /**
    * @dev start new round 
    */
    function startNewRound() public onlyOperator isLotteryActive isRoundFinished {
        blockNumber = block.number;
        roundTime = blockNumber + M;
        changePhaseRound(roundPhase.Active);
        //TODO cntrollare cosa altro c'è da fare per iniziare un nuovo round
    }

    /**
    * @dev permitt to the users to buy the ticket 
    */
    function buy(uint[] memory pickedNumbers) isLotteryActive isRoundActive public payable {
        require(block.number < roundTime, "The operator has not closed the round, but the round time has ended");
        uint money = msg.value;
        uint change;
		require(money >= TKT_PRICE, "200000 gwei are required to buy a ticket");
        require(pickedNumbers.length == 6, "Pick 5 standard numbers and a powerball");
        bool[69] memory checkN; //side array used to check duplicates with direct access
        for (uint i=0; i<69; i++) {
            checkN[i] = false;
        }

        //check numbers conformity
        for(uint i = 0; i < pickedNumbers.length; i++) {
            if(i != 5) {
                require(pickedNumbers[i] >= 1 && pickedNumbers[i] <= 69, "Choose a number in the range from 1 to 69");
                require(!checkN[pickedNumbers[i]-1], "Duplicates not allowed");
                checkN[pickedNumbers[i]-1] = true;
            }
            else {
                require(pickedNumbers[i] >= 1 && pickedNumbers[i] <= 26, "Choose a Powerball number in the range from 1 to 26");
            } 
        }

        //emit an event ticket bought or log ticket bought
        emit Log("Ticket Lottery purchased", msg.sender);
         //track player ticket 
        bets.push(Ticket(msg.sender, pickedNumbers, pickedNumbers[5], 0, false, false));
        //gamblers.push(msg.sender);

        //give back the change
        if(money > TKT_PRICE) {
            change = msg.value - TKT_PRICE;
            // Reimbourse the change
            payable(msg.sender).transfer(change);
        }

	}

    //TODO: decidere dove controllare se gli utenti hanno acquistato biglietti e poi la 
    //lotteria è stata chiusa. vanno restituiti i soldi

    /**
    * @dev used by the lottery operator to draw numbers of the current lottery round
    */
    function drawNumbers() public onlyOperator isLotteryActive isRoundActive {
        require(block.number >= roundTime, "The Round is not Closed, is not the time to draw");

        bool[69] memory checkN;
        for (uint i = 0; i < 69; i++) {
            checkN[i] = false;
        }
        //number drawn
        uint extractedN;
        
        uint seed = 0;

        for (uint i = 0; i < 5; i++) {
            
            /**
            * number generator using the block stimestemp, sender address and the
            * the hash of the block of height at least X+K, where X is the height of 
            * the block corresponding to the end of R and K is a parameter
            */
            extractedN = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, roundTime + K, seed))) % 69) + 1;
            //check if the number is repeated or not
            if( checkN[extractedN-1] ) {
                i -= 1;
            }
            else {
                luckyNumbers[i] = extractedN;
                checkN[extractedN-1] = true;

            }
            //increment seed to avoid repetition
            seed++;
        }

        //powerball number
        luckyNumbers[5] = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, roundTime + K, seed))) % 26) + 1;
        emit Log("The Lottery Operator has drawn the winning numbers and the Powerball number", msg.sender);
        //close the round
        changePhaseRound(roundPhase.Closed);
        //TODO: chiamare la funzione che assegna i premi

        givePrizes(luckyNumbers);
    }

    /**
    * @dev used by lottery operator to distribute the prizes of the current lottery round
    */
    function givePrizes(uint[] memory _luckyNumbers) public onlyOperator isLotteryActive isRoundClosed {
        require(!arePrizesAwarded, "Prizes already Awarded");

        uint wPowerball = _luckyNumbers[5];
        uint[] memory ticketNumbers;

        for (uint i = 0; i < bets.length; i++) {
            ticketNumbers = bets[i].numbers;
            for (uint j = 0; j < _luckyNumbers.length; i++) {
                for (uint k = 0; k < ticketNumbers.length; i++) {
                    if (ticketNumbers[j] == _luckyNumbers[i]) {
                        bets[i].matchesN ++;
                        break;
                    }
                }
            }
            if (bets[i].powerball == wPowerball) {
                bets[i].matchesPb = true;
            }

            if (bets[i].matchesN > 0 || bets[i].matchesPb)
                bets[i].isLucky = true;
        }

        uint kittyClass;
        uint nm;
        bool p;
        //TODO: dopo aver controllato i biglietti vincenti devo assegnare i premi
         for (uint i = 0; i < bets.length; i++){ //for each bet in the round
            nm = bets[i].matchesN;
            p = bets[i].matchesPb;

            if (nm == 5 && p)
                //kitty of class 1
                kittyClass = 1;
            else if ( nm == 5 && !p)
                //kitty of class 2
                kittyClass = 2;
            else if (nm == 4 && p)
                //kitty of class 3
                kittyClass = 3;
            else if (nm == 4 && !p)
                //kitty of class 4
                kittyClass = 4;
            else if (nm == 3 && p)
                //kitty of class 4
                kittyClass = 4;
            else if (nm == 3 && !p)
                //kitty of class 5
                kittyClass = 5;
            else if (nm == 2 && p)
                //kitty of class 5
                kittyClass = 5;
            else if (nm == 2 && !p)
                //kitty of class 6
                kittyClass = 6;
            else if (nm == 1 && p)
                //kitty of class 6
                kittyClass = 6;
            else if (nm == 1 && !p)
                //kitty of class 7
                kittyClass = 7;
            else if (nm == 0 && p)
                //kitty of class 8
                kittyClass = 8;

            //assign the prize and mint a new one
            uint kittyId = tryNft.getTokenOfClassX(kittyClass);
            tryNft.awardItem(operator, bets[i].gambler, kittyId);
            mint(kittyClass);

            emit prizeAwarded("The Gambler has been awarded", bets[i].gambler, kittyClass);
        }

        //set true the variable used to check if the prizes have been awarded
        arePrizesAwarded = true;
        
        changePhaseRound(roundPhase.Finished);

        withdraw(operator);


        //cleanup bets
        delete bets;
    }

    /**
    * @dev used to mint new collectible
    */
    function mint(uint _class) public onlyOperator isLotteryActive {
        tryNft.safeMint(_class);

        emit Log("The Lottery Operator has mint a new Prize", msg.sender);
    }

    /**
    * @dev used by the lottery operator to deactivate the lottery contract
    */    
    function closeLottery() public payable isLotteryActive onlyOperator {
		changeLotteryState(lotteryState.Closed);

        //controlla se il round era attivo, nel caso vanno rimborsati tutti i giocatori

        //TODO: check if lottery contract is Active or Not, possibly check the check with round
	}

    

}