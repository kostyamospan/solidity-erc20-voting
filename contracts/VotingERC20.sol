// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
//pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VoterERC20 is ERC20 {
    Voting DEFAULT_VOTING;

    Proposal DEFAULT_PROPOSAL;

    Voting[] public votings;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    modifier onlyValidTokenOwner() {
        uint256 procentage = (balanceOf(msg.sender) * 100) / totalSupply();
        // console.log("Token owner has ", procentage, "of bank emission");

        require(
            procentage >= 5,
            "Token owner must have >= 5% of bank emission."
        );
        _;
    }

    modifier notExpiredVoting(uint256 votingId) {
        Voting storage voting = votings[votingId];

        require(voting.creationTimestamp != 0, "Voting is not exist");

        if (voting.creationTimestamp + voting.duration > block.timestamp) {
            _;
        } else {
            finishVoting(votingId);
            require(false, "Voting is finished");
        }
    }

    function getProposalInfo(uint256 _id, uint256 _proposalId)
        public
        view
        returns (string memory, uint256)
    {
        return (
            votings[_id].proposals[_proposalId].name,
            votings[_id].proposals[_proposalId].votes
        );
    }

    function getVotingsCount() public view returns (uint256) {
        return votings.length;
    }

    function isVoted(uint256 _id) public view returns (bool) {
        return votings[_id].isVoted[msg.sender];
    }

    function getAllVotings() public view returns (VotingInfo[] memory) {
        VotingInfo[] memory info = new VotingInfo[](votings.length);

        for (uint256 i; i < votings.length; i++) {
            info[i] = VotingInfo(
                votings[i].votingStatus,
                votings[i].creationTimestamp,
                votings[i].duration,
                votings[i].proposalsCount
            );
        }

        return info;
    }

    function getAllProposals(uint256 _id)
        public
        view
        returns (Proposal[] memory)
    {
        Voting storage v = votings[_id];

        Proposal[] memory proposals = new Proposal[](v.proposalsCount);

        for (uint256 i = 0; i < v.proposalsCount; i++) {
            proposals[i] = v.proposals[i];
        }

        return proposals;
    }

    function createVoting(
        bytes32[] memory proposals,
        uint256 votingDurationSeconds
    ) public onlyValidTokenOwner returns (uint256) {
        votings.push();

        Voting storage newVoting = votings[votings.length - 1];

        newVoting.proposalsCount = 0;
        newVoting.votingStatus = VotingStatus.ACTIVE;
        newVoting.creationTimestamp = block.timestamp;
        newVoting.duration = votingDurationSeconds;

        for (uint256 i = 0; i < proposals.length; i++) {
            string memory proposal = bytes32ToString(proposals[i]);

            require(
                !contains(newVoting, proposal),
                "Dublicated voting proposal"
            );
            addProposal(newVoting, proposal);
        }

        return votings.length - 1;
    }

    function endVoting(uint256 votingId) public {
        Voting storage voting = votings[votingId];

        require(voting.creationTimestamp != 0, "Voting is not exist");
        require(
            block.timestamp - voting.duration > voting.creationTimestamp,
            "Voting does not expired yet"
        );

        finishVoting(votingId);
    }

    function getWinnerProposal(uint256 votingId)
        public
        view
        returns (string memory)
    {
        Voting storage voting = votings[votingId];

        require(voting.creationTimestamp != 0, "This voting doesnt exist");
        require(
            voting.votingStatus == VotingStatus.FINISHED,
            "This voting is didnt finished"
        );

        return calculateWinnerProposal(voting).name;
    }

    function vote(uint256 votingId, string memory proposal)
        public
        notExpiredVoting(votingId)
    {
        Voting storage voting = votings[votingId];

        require(!voting.isVoted[msg.sender], "Already voted");

        Proposal storage p = getProposalByName(voting, proposal);

        require(p.isValue, "The proposal does not exist");

        voting.isVoted[msg.sender] = true;
        p.votes += balanceOf(msg.sender);
    }

    function addProposal(Voting storage voting, string memory proposal)
        private
    {
        voting.proposals[voting.proposalsCount++] = Proposal(proposal, 0, true);
    }

    function calculateWinnerProposal(Voting storage voting)
        private
        view
        returns (Proposal memory)
    {
        Proposal memory maxVote = voting.proposals[0];

        for (uint256 i = 0; i < voting.proposalsCount; i++) {
            if (voting.proposals[i].votes > maxVote.votes) {
                maxVote = voting.proposals[i];
            }
        }

        return maxVote;
    }

    function contains(Voting storage voting, string memory value)
        private
        view
        returns (bool)
    {
        for (uint256 i; i < voting.proposalsCount; i++) {
            if (strcmp(voting.proposals[i].name, value)) {
                return true;
            }
        }

        return false;
    }

    function getProposalByName(Voting storage voting, string memory name)
        private
        view
        returns (Proposal storage)
    {
        for (uint256 i = 0; i < voting.proposalsCount; i++) {
            if (strcmp(voting.proposals[i].name, name)) {
                return voting.proposals[i];
            }
        }

        return DEFAULT_PROPOSAL;
    }

    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;

        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));

            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);

        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }

        return string(bytesStringTrimmed);
    }

    function finishVoting(uint256 votingId) private {
        votings[votingId].votingStatus = VotingStatus.FINISHED;
    }

    function strcmp(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    enum VotingStatus {ACTIVE, FINISHED, CANCELLED}

    struct VotingInfo {
        VotingStatus votingStatus;
        uint256 creationTimestamp;
        uint256 duration;
        uint256 proposalsCount;
    }

    struct Voting {
        VotingStatus votingStatus;
        uint256 creationTimestamp;
        uint256 duration;
        uint256 proposalsCount;
        mapping(uint256 => Proposal) proposals;
        mapping(address => bool) isVoted;
    }

    struct Proposal {
        string name;
        uint256 votes;
        bool isValue;
    }
}
