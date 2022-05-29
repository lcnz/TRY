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
    
    function withdraw() public onlyOperator {
       operator.transfer(address(this).balance);
    }

    uint[] numbers;
    uint powerball;

    uint blockNumber; //initial round block number
    uint constant M = 150; //lottery fixed duration 30 mins
    uint constant K = 42; //fixed parameter K
    uint constant D = 10; //10 blocks represent 2 minutes delay
    uint constant TKT_PRICE = 200000 gwei; //ticket price

    bool prizesAwarded;

    TryKitty tryNft; //prize

    //struct that represents a ticket
    struct Ticket {
        uint[] stdNumbers;
        uint pwrBall;
        uint matchesN;
        bool matchesPb;
    }
    //maps the ticket number to player
    mapping(address => Ticket[]) bets;

    //list of winners.
    address[] winners;

    //maps the tokenID to the class of prize
    mapping(uint => uint256[]) prizeClasses;

    //list of tokenIDs
    uint[] Ids;

    enum roundPhase{ Active, Closed, Finished }
    roundPhase phase;

    enum lotteryState{ Active, Closed }
    lotteryState state;

    //event to log round phase and lottery state
    event LotteryStateChanged(string eventLog, lotteryState newState);
    event RoundPhaseChanged(string eventLog, roundPhase newPhase);
    
    //to ensure the current phase of the round is the correct one
    modifier isRoundFinished() {
        require(phase == roundPhase.Active, "New Round can start once the previoud is Finished");
        _;
    }

    modifier isRoundActive() {
        require(phase == roundPhase.Active, "Round is over, come back next time");
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
    event TicketPurchased(string eventLog, address caller);
    event NumbersDrawn(string eventLog, address caller);
    

    constructor() {

        operator = payable(msg.sender);        
        prizesAwarded = true;
        tryNft = new TryKitty();

        //activate the lottery and the round
        changeLotteryState(lotteryState.Active);
        //changePhaseRound(roundPhase.Active); meglio chiamare start New ROund
        //generates the first 8 prizes, one for each class
        for (uint i = 0; i<8; i++) {
            //track tokeId to the class 
            prizeClasses[i+1].push(tryNft.safeMint(operator, i+1));
        }
    }

    /**
    * @dev start new round 
    */
    function startNewRound() public onlyOperator isLotteryActive isRoundFinished {
        blockNumber = block.number;
        changePhaseRound(roundPhase.Active);
        //TODO cntrollare cosa altro c'è da fare per iniziare un nuovo round
    }

    /**
    * @dev permitt to the users to buy the ticket 
    */
    function buy(uint[] memory pickedNumbers) isLotteryActive isRoundActive public payable {
        uint money = msg.value;
        uint change;
		require(money >= TKT_PRICE, "200000 gwei are required to buy a ticket");
        require(pickedNumbers.length == 6, "Pick 5 standard numbers and a powerball");
        bool[69] memory checkN; //side array used to check duplicates with direct access
        uint[] memory stdN;
        for (uint i=0; i<69; i++) {
            checkN[i] = false;
        }
        uint pwrB;

        //check numbers conformity
        for(uint i = 0; i < pickedNumbers.length; i++) {
            if(i != 5) {
                require(pickedNumbers[i] >= 1 && pickedNumbers[i] <= 69, "Choose a number in the range from 1 to 69");
                require(!checkN[pickedNumbers[i]-1], "Duplicates not allowed");
                checkN[pickedNumbers[i]-1] = true;
            }
            else {
                require(pickedNumbers[i] >= 1 && pickedNumbers[i] <= 26, "Choose a Powerball number in the range from 1 to 26");
                pwrB = pickedNumbers[i];
            } 
        }

        //emit an event ticket bought or log ticket bought
        emit TicketPurchased("Ticket Lottery purchased", msg.sender);
         //track player ticket 
        bets[msg.sender].push(Ticket(stdN, pwrB, 0, false));

        if(money > TKT_PRICE) {
            change = msg.value - TKT_PRICE;
            // Reimbourse the change
            payable(msg.sender).transfer(change);
        }
	}

    /**
    * @dev used by the lottery operator to draw numbers of the current lottery round
    */
    function drawNumbers() public view onlyOperator isLotteryActive returns(uint[] memory drawed) {
        require(block.number % M == 0, "The Round is not Closed, is not the time to draw");

    }

    /**
    * @dev used by lottery operator to distribute the prizes of the current lottery round
    */
    function givePrizes() public onlyOperator isLotteryActive isRoundFinished {
        
    }

    /**
    * @dev used to mint new collectibles
    */
    function mint() public onlyOperator isLotteryActive isRoundFinished {
        
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