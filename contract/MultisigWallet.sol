// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

contract MultisigWallet{
    event ProposalSubmitted(
        address indexed owner,
        uint256 indexed proposalId,
        address indexed to,
        uint256 value,
        bytes data
    );

    event ProposalApproved(
        uint256 indexed proposalId,
        address indexed approvedBy
    );

      event ProposalApprovalRevoked(
        uint256 indexed proposalId,
        address indexed revokedBy
    );

      event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executedBy
    );

    event Deposit(
        uint256 value,
        address indexed depositedBy
    );


    address[] public owners;
    uint256 private MIN_SIG_REQUIRED;
    mapping(uint256 => mapping(address => bool)) approvals;
    
    constructor(uint256 minSigRequired){
        MIN_SIG_REQUIRED = minSigRequired;
        owners.push(msg.sender);
    }

    receive() external payable {
        emit Deposit(msg.value, msg.sender);
    }

    struct Proposal{
        uint256 id;
        address to;
        uint256 value;
        bytes data; 
        bool executed;
    }

    uint256 public proposalIndex;
    mapping(uint256 => Proposal) public proposals;
    uint256[] public pendingProposal;

   
    function addOwner(address owner) public onlyOwner{
        require(owner != address(0), "invalid address");
        owners.push(owner);
    }

    function submitProposal(address to, uint value, bytes calldata data) public onlyOwner returns (uint256 pId) {
        uint proposalId = proposalIndex++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            to: to,
            value: value,
            data: data,
            executed: false
        });

        pendingProposal.push(proposalId);
        emit ProposalSubmitted(msg.sender, proposalId, to, value, data);
        return pId;
    }

    function approve(uint256 pId) public onlyOwner validProposal(pId) notApproved(pId) notExecuted(pId){
        approvals[pId][msg.sender] = true;
        emit ProposalApproved(pId, msg.sender);
    }

    modifier validProposal(uint256 pId){
        require(pId <= proposalIndex, "Invalid Proposal!");
        _;
    }

    modifier onlyOwner(){
        require(isOwner(), "Only owner can execute!");
        _;
    }

    modifier notApproved(uint256 pId){
        require(!approvals[pId][msg.sender], "Already approved");
        _;
    }

    modifier requirementMet(uint256 pId){
        require(approvalCount(pId) >= MIN_SIG_REQUIRED, "Not enough approval.");
        _;
    }

    function isOwner() internal view returns(bool){
        for(uint256 i; i< owners.length; i++){
            if(owners[i] == msg.sender){
                return true;
            }
        }   

        return false;   
    }

    function approvalCount(uint256 pId) public view returns(uint256 count){
        for(uint256 i; i< owners.length; i++){
            if(approvals[pId][owners[i]]){
                count++;
            }
        }       
    }

    modifier notExecuted(uint256 pId){
        require(!proposals[pId].executed, "Already executed!");
        _;
    }

    function executeProposal(uint256 pId) public validProposal(pId) onlyOwner notExecuted(pId) requirementMet(pId)  returns(bool isSuccess){
        Proposal storage proposal = proposals[pId];
        proposal.executed = true;
        removeProposal(pId);    
        (bool Success,) = proposal.to.call{value: proposal.value}(proposal.data);
        require(Success, "Tx failed!");
        emit ProposalExecuted(pId, msg.sender);
        return true;
    }

    function removeProposal(uint256 pId) private{
        uint pIndex;
        for(uint256 i=0; i < pendingProposal.length; i++){
            if(pendingProposal[i] == pId){
                pIndex = i;
            }
        }
        //removing element without preserving order
        pendingProposal[pIndex] = pendingProposal[pendingProposal.length -1];     
        pendingProposal.pop();
    }

    function revoke(uint256 pId)public  onlyOwner validProposal(pId) notExecuted(pId){
         approvals[pId][msg.sender] = false;
         emit ProposalApprovalRevoked(pId, msg.sender);
    }

}