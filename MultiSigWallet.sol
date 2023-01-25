// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txID);
    event Approve(address indexed owner, uint indexed txID);
    event Revoke(address indexed owner, uint indexed txID);
    event Execute(uint indexed txID);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool isExecuted;
    }

    address[] public owners;
    mapping(address => bool) public isOwner; // is this address one of the owners
    uint public requiredApprovals;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;
    
    //Here the mapping provides a more gas efficient way to make the check
    //as opposed to looping through the owners array
    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not the owner");
        _;
    }
    
    modifier txExists(uint _txID) {
    	require(_txID < transactions.length, "Transaction does not exist");
    	_;
    }

    modifier notApproved(uint _txID) {
        require(!approved[_txID][mesg.sender], "Transaction already approved");
        _;
    }

    modifier notExecuted(uint _txID) {
        require(!transactions[_txID].isExecuted), "Transaction already executed";
        _;
    }
    
    // Tie in owners and the number of required approvals
    constructor(address[] memory _owners, uint _requiredApprovals) {
        require(_owners.length > 0, "Owners required");
        require(_requiredApprovals > 0 && _required <= owners.length,
        "Invalid number of approvals");
        
        for(uint i; i < _owners.length; i++) {
        	address owner = _owners[i];
        	require(owner != adress(0), "Invalid owner address");
        	require(!isOwner[owner], "Owner is not unique/already an owner");
        	
    			isOwner[owner] = true;
    			owners.push(owner);
        }
        requiredApprovals = _requiredApprovals
    }
    
    receive() external payable {
    	emit Deposit(msg.sender, msg.value);
    }
    
    function submit(address _to, uint _value, bytes calldata _data) 
    public onlyOwner
    {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            isExecuted: false
        }));
        emit Submit(transactions.length - 1);
    }
    
    function approve() 
    public onlyOwner txExists(_txID) notApproved(_txID) notExecuted(_txID)
    {
        approved[_txID][msg.sender] = true;
        emit Approved(msg.sender, _txID);
    }

    function _getApprovalCount(uint _txID) private view returns(uint count) {
        for(uint i; i < owners.length; i++) {
            if(approved[_txID][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }

    function execute(uint _txID) external txExists notExecuted {
        require(_getApprovalCount >= requiredApprovals, "Needs more approvals");
        Transaction storage tranaction = transactions[_txID];

        transaction.isExecuted = true;

        (bool success, ) = transactions.to.call{value: transactions.value} (
            transaction.data);

        require(success == true, "Transaction failed");

        emit Execute(_txID);
    }
    
		function revoke(uint _txID) external txExists notExecuted {
			require(approved[_txID][msg.sender], "Transaction not approved");
			approved[_txID][msg.sender] = false;

			emit Revoke(msg.sender, _txID);
    }
}
