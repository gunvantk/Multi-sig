// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13

contract MultisigWallet{
    address[] public owners;
    uint256 private MIN_SIG_REQUIRED;
    mapping(uint256 => mapping(address => bool)) approvals;
    
    struct Proposal{
        uint256 Id,
        address To,
        uint256 Value,
        calldata Data, 
        bool Executed
    }

    Proposal[] public proposal;

    constructor(uint256 minSigRequired){
        MIN_SIG_REQUIRED = minSigRequired;
    }


    function addOwner(address owner) onlyOwner{
        require(owners != address(0), "invalid address");
        owners.push(owner);
    }

    function addProposal(address to, calldata data) onlyOwner return uint256{
        proposal.push(Proposal{
            Id: proposal.length +1
            To: to,
            Value: msg.value,
            Data: data
        })

        for(uint256 i; i< owners.length; i++){
           approvals[pId][owners[i]] = false;
        }   

        return proposal.length;
    }

    function approve(uint256 pId) onlyOwner validProposal notApproved notExecuted{
        approvals[pId][msg.sender] = true;
    }

    modifier validProposal(uint256 pId){
        require(pId <= proposals.length, "Invalid Proposal!");
        _;
    }

    modifier onlyOwner(){
        require(isOwner(), "Only owner can execute!");
        _;
    }

    modifier notApproved(uint256 pId){
        require(!approvals[pId][msg.sender], "Already approved");
        _:
    }

    modifier requirementMet(pId){
        require(approvalount(pId) >= MIN_SIG_REQUIRED, "Not enough approval.")
    }

    function isOwner() internal return bool{
        for(uint256 i; i< owners.length; i++){
            if(owners[i] == msg.sender){
                return true;
            }
        }   

        returns false;   
    }

    function approvalount(uint256 pId) public view return uint256 count{
        for(uint256 i; i< owners.length; i++){
            if(approvals[pId][owners[i]]){
                count++;
            }
        }       
    }

    modifier notExecuted(uint256 pId){
        require(!proposal[pId-1].Executed, "Already executed!")
    }

    function executeProposal(uint256 pId) validProposal OonlyOwner notExecuted requirementMet  return bool{
        Proposal storage proposal = proposals[pId -1];
        proposal.Executed = true;

        (bool Success,) = proposal.to.call{value= proposal.Value}(proposal.data);
        require(Success, "Tx failed!");

    }

    function revoke(uint256 pid) onlyOwner validProposal notExecuted{
         approvals[pId][msg.sender] = false;
    }

}