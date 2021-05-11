// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0-solc-0.7/contracts/token/ERC20/ERC20.sol";
import "./console.sol";
// nethereum - discord
// hardhat - discord
// buildingcrypto
// in search - "blockchain developers"
contract VoterERC20 is ERC20 {
    Voting DEFAULT_VOTING; // todo: ask about this
    Proposal DEFAULT_PROPOSAL;
    Voting[] public votings;
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    } 
    modifier onlyValidTokenOwner() {
        uint256 procentage = balanceOf(msg.sender) * 100 / totalSupply();
        console.log("Token owner has ", procentage, "of bank emission");
        require( procentage >= 5 ,"Token owner must have >= 5% of bank emission.");
        _;
    } 
    modifier notExpiredVoting(uint votingId) {
        Voting storage voting = votings[votingId];
        require(voting.creationTimestamp != 0, "Voting is not exist");
        if(voting.creationTimestamp + voting.duration > block.timestamp) {
            _;    
        }else { 
            finishVoting(votingId);
            require(false, "Voting is finished");
        }
    } 
    function createVoting(bytes32[] memory proposals, uint256 votingDurationSeconds) public onlyValidTokenOwner returns (uint) {    
        votings.push();
        Voting storage newVoting = votings[votings.length-1]; 
        newVoting.proposalsCount = 0;
        newVoting.votingStatus = VotingStatus.ACTIVE;
        newVoting.creationTimestamp =  block.timestamp;
        newVoting.duration =  votingDurationSeconds;
        for(uint i = 0; i < proposals.length; i++) { 
            string memory proposal = bytes32ToString(proposals[i]);
            require(!contains(newVoting, proposal), "Dublicated voting proposal");            
            addProposal(newVoting, proposal);
        }
        return votings.length;
    } 
    function endVoting(uint votingId) public {    
        Voting storage voting = votings[votingId];
        require(voting.creationTimestamp != 0, "Voting is not exist");
        require(block.timestamp - voting.duration > voting.creationTimestamp, "Voting does not expired yet"); // todo rephrase
        finishVoting(votingId);
    } 
    function getWinnerProposal(uint votingId) public view returns (string memory){  
        Voting storage voting = votings[votingId];
        require(voting.creationTimestamp != 0, "This voting doesnt exist");
        require(voting.votingStatus == VotingStatus.FINISHED, "This voting is didnt finished");
        return calculateWinnerProposal(voting).name;
    }
    function vote(uint votingId,string memory proposal) notExpiredVoting(votingId) public{  
        Voting storage voting = votings[votingId];
        require(!voting.isVoted[msg.sender], "Already voted");
        Proposal storage p = getProposalByName(voting, proposal);
        require(p.isValue, "The proposal does not exist");
        voting.isVoted[msg.sender] = true;
        p.votes += balanceOf(msg.sender);
    } 
    function addProposal(Voting storage voting, string memory proposal) private { 
        voting.proposals[voting.proposalsCount++] = Proposal(proposal, 0, true);
    }
    function calculateWinnerProposal(Voting storage voting) private view returns (Proposal memory){
        Proposal memory maxVote = voting.proposals[0];
        for (uint i = 0; i< voting.proposalsCount;i++){ 
            if(voting.proposals[i].votes > maxVote.votes) { 
                maxVote = voting.proposals[i];
            }   
        } 
        return maxVote;
    } 
    function contains(Voting storage voting, string memory value) private view returns (bool){
        for (uint i; i< voting.proposalsCount;i++){
          if (strcmp(voting.proposals[i].name, value)) {
            return true;  
          }
        }
        return false;
    } 
    function getProposalByName(Voting storage voting, string memory name) private view returns (Proposal storage){
        for (uint i = 0; i< voting.proposalsCount;i++){
          if (strcmp(voting.proposals[i].name, name)) {
            return voting.proposals[i];
          }
        }
        return DEFAULT_PROPOSAL;
    }
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    function finishVoting(uint votingId)  private { 
        votings[votingId].votingStatus = VotingStatus.FINISHED;
    }    
    function strcmp(string memory a, string memory b) private pure returns (bool) { 
        return keccak256(bytes(a)) == keccak256(bytes(b));
    } 
    enum VotingStatus {ACTIVE, FINISHED, CANCELLED }
    struct Voting {
        VotingStatus votingStatus;
        uint256 creationTimestamp;
        uint256 duration;
        uint proposalsCount;
        mapping(uint => Proposal) proposals;
        mapping(address => bool) isVoted;
    }
    struct Proposal {
        string  name;  
        uint256 votes;
        bool isValue;
    }
}