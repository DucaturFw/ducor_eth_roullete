pragma solidity ^0.4.24;
import openzeppelin-solidity/contracts/ownership/Ownable.sol;

contract MasterOracle is Ownable {
    event DataRequest(string name, address receiver, string memo);
    event DataRequest(string name, address receiver, string memo, int[] params);
    function request_data(string name, address receiver, string memo) public {
        emit DataRequest(name, receiver, memo);
    }
    function request_data_args(string name, address receiver, string memo, int[] params) public {
        emit DataRequest(name, receiver, memo, params);
    }
}

contract Oraclized is Ownable {
    address data_provider;
    address data_publisher;
    int rand_from = 0;
    int rand_to = 36;
    event DataPushed(string name, string memo, uint value);

    constructor(address master_oracle, address data_pub) {
        data_provider = master_oracle;
        data_publisher = data_pub;
    }

    modifier onlyDataPublisher() {
        require(data_publisher == msg.sender);
        _;
    }

    function push_data_uint(string name, uint value, string memo) onlyDataPublisher public {
        emit DataPushed(name, memo, value);
    }

    function request_random(string memo) public {
        MasterOracle master = MasterOracle(data_provider);
        int256[] memory args;
        args[0] = rand_from;
        args[1] = rand_to;
        master.request_data_args('HASH_OF_REQUIRED_RANDOM', this, memo, args);
    }
}

contract DucorRoulette is Oraclized {
    int rand_from = 0;
    int rand_to = 36;
    event GameEnd(uint id, uint value);
    event StartGame(uint id);

    struct Bet {
        mapping(uint8 => uint) marks;
        uint8 bet_size;
    }

    struct Round {
        mapping(address => Bet) bets;
        uint8 state; // 0 - joinable, 1 - awaiting results, 2 - finished
        uint8 random_value;
    }

    uint curr_game_id = 0;
    mapping(uint => Round) games;

    function makeBet(uint8[] marks) payable public {
        uint gid = curr_game_id + ((games[curr_game_id].state == 1) ? 1 : 0); // join current or next game
        games[gid].bets[msg.sender].bet_size = uint8(marks.length);
        for (uint i = 0; i < marks.length; ++i) {
            games[gid].bets[msg.sender].marks[marks[i]] = msg.value;
        }
    }

    function push_data_uint(string name, uint value, string memo) onlyDataPublisher public {
        games[curr_game_id].state = 2;
        games[curr_game_id].random_value = uint8(value);

        emit GameEnd(curr_game_id, value);
        curr_game_id += 1;

        super.push_data_uint(name, value, memo);
    }

    function request_random(string memo) private {
        super.request_random(memo);
    }

    function gameRoll() onlyOwner public {
        games[curr_game_id].state = 1;
        emit StartGame(curr_game_id);
        request_random("");
    }

    function calcPrize(uint8 bet_size, uint bet) pure returns(uint) {
        if (bet_size > 18) {
            return bet * 2;
        } else if (bet_size > 6) {
            return bet * 3;
        } else if (bet_size > 4) {
            return bet * 6;
        } else if (bet_size > 3) {
            return bet * 9;
        } else if (bet_size > 2) {
            return bet * 12;
        } else if (bet_size > 1) {
            return bet * 18;
        } else if (bet_size > 0) {
            return bet * 35;
        } else {
            revert();
        }
    }

    function getPrize(uint game_id) payable {
        msg.sender.transfer(calcPrize(games[game_id].bets[msg.sender].marks[games[game_id].random_value]));
    }
}