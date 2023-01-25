//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract CryptoTrust {
    //Parent owner object
    address owner;
    
    event LogKidFundingReceived(address addr, uint amount, uint contractBalance);


    constructor () {
        owner = msg.sender;
    }


    //Child object
    struct Kid {
        address payable walletAddress;
        string firstName;
        string lastName;
        uint releaseTime;
        uint amount;
        bool canWithdraw;
    }

    Kid[] public kids;

    //Add child to contract
    modifier onlyOwner() {
        require(msg.sender == owner, "This is not your CryptoTrust");
        _;
    } 

    function addKid (address payable _walletAddress, string memory _firstName, 
    string memory _lastName, uint _releaseTime, uint _amount, bool _canWithdraw) public onlyOwner {
        kids.push(Kid (
            _walletAddress,
            _firstName,
            _lastName,
            _releaseTime,
            _amount,
            _canWithdraw
        ));
    }

    function balanceOf() public view returns(uint256) {
        return address(this).balance;
    }

    //Deposit funds to contract -> individual child's account
    function deposit(address _walletAddress) payable public {
        addToKidsBalance(_walletAddress);
    }

    function addToKidsBalance(address _walletAddress) private {
        for(uint i=0; i<kids.length; i++) {
            if(kids[i].walletAddress == _walletAddress) {
                kids[i].amount += msg.value;
                emit LogKidFundingReceived(_walletAddress, msg.value, balanceOf);
            }
        }
    }

    //Child can check if able to withdraw
    function getIndex(address _walletAddress) view private returns(uint) {
        for(uint i=0; i<kids.length; i++) {
            if(kids[i].walletAddress == _walletAddress) {
                return i;
            }
        }
        return 1000; // placeholder if nothing found
    }

    function availableToWithdraw(address _walletAddress) public returns(bool) {
        uint i = getIndex(_walletAddress);
        if(block.timestamp > kids[i].releaseTime) {
            kids[i].canWithdraw = true;
            return true;
        } else {
            return false;
        }
    } 

    //Child fund withdrawal
    function withdrawFunds(address payable _walletAddress) payable public {
        uint i = getIndex(_walletAddress);
        require(msg.sender == kids[i].walletAddress, "These are not your funds");
        require(kids[i].canWithdraw == true, "You cannot withdraw yet");
        kids[i].walletAddress.transfer(kids[i].amount);
    }

}
