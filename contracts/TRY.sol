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
    
    uint[] numbers;
    uint powerball;

    uint blockNumber; //initial round block number
    uint constant M_BLOCKS = 150; //lottery fixed duration 30 mins
    uint constant K = 42; //lottery fixed duration 30 mins
    uint constant TKT_PRICE = 200000 gwei; //ticket price
    uint totalBalance; //contract balance

    TryKitty nft; //prize

    //struct that represents a ticket
    struct Ticket {
        uint[] stdNumbers;
        uint pwrBall;
    }
    //maps the ticket number to player
    mapping(address => Ticket[]) bets;

    //list of winners.
    address[] winners;

    //maps the tokenID to the prize
    mapping(uint => TryKitty) prizes;

    //maps the tokenID to the class of prize
    mapping(uint => uint) classes;

    //list of tokenIDs
    uint[] Ids;

    enum roundPhase{ Active, Closed, Finished }
    roundPhase phase;

    enum lotteryState{ Active, Closed }
    lotteryState state;

    //event to log round phase and lottery state
   	event RoundPhaseChanged(roundPhase newPhase);
    event RoundFinished(roundPhase roundFinished);
    event LotteryStateClosed(lotteryState closedState);

    //to ensure the current phase of the round is the correct one
    modifier isPhase(roundPhase _phase) {
        require(phase == _phase, "Wrong round phase for this action");
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
    //function that change the round phase
    function _changeState(lotteryState _newState) private {
		state = _newState;
		emit LotteryStateClosed(state);
	}

    function startNewRound() public onlyOwner {

    }

    //function that change the lottery state in closed, in order to deactivate the Lottery
    function closeLottery() public payable isLotteryActive onlyOperator {
		state = lotteryState.Closed;
		emit LotteryStateClosed(state);

        //controlla se il round era attivo, nel caso vanno rimborsati tutti i giocatori
	}

    //TODO: check if lottery contract is Active or Not, possibly check the check with round

    //useful event to log what happen
    event Log(string eventLog, address caller);
    event TicketPurchased(string eventLog, address caller);
    event NumbersDrawn(string eventLog, address caller);
    

    constructor() {
        require(msg.sender == operator, "This function is only for the Lottery Operator");
        
        totalBalance = 0;
        operator = msg.sender;
    }

    /**
    * @dev permitt to the users to buy the ticket 
    */
    function buyTicket(uint[] memory pickedNumbers) public payable isLotteryActive() isRoundActive() {
        uint money = msg.value;
        address player = msg.sender;
		require(money >= TKT_PRICE, "200000 gwei are required to buy a ticket");
        require(pickedNumbers.length == 6, "Pick 5 standard numbers and a powerball");
        bool[69] memory stdN; //side array used to check duplicates with direct access
        for (uint i=0; i<69; i++) {
            stdN[i] = false;
        }
        uint pwrB;

        //check numbers conformity
        for(uint i = 0; i < pickedNumbers.length; i++) {
            if(i != 5) {
                require(pickedNumbers[i] >= 1 && pickedNumbers[i] <= 69, "Choose a number in the range from 1 to 69");
                require(!stdN[pickedNumbers[i]-1], "Duplicates not allowed");
                stdN[pickedNumbers[i]-1] = true;
            }
            else {
                require(pickedNumbers[i] >= 1 && pickedNumbers[i] <= 26, "Choose a Powerball number in the range from 1 to 26");
                pwrB = pickedNumbers[i];
            } 
        }

        //increase the balance of the contract
        totalBalance += money;

        //emit an event ticket bought or log ticket bought

         //track player ticket 
        bets[msg.sender].push(Ticket({
        	stdNumbers: stdN,
        	pwrBall: pwrB
        	}));
	}
}