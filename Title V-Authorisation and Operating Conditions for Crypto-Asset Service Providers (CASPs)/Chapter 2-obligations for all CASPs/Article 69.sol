// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 69
contract CASPNotificationRegistry {
    struct ManagementChange {
        string newMemberName;
        uint256 startDate;
        bytes32 detailsHash;  // Proof of repute, qualifications, experience
        uint256 submissionDate;
        bool isAcknowledged;
        uint256 acknowledgmentDate;
    }

    struct CASP {
        bool isAuthorized;
        ManagementChange[] managementChanges;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    mapping(address => bool) public ncAuthority;

    event ManagementChangeNotified(
        address indexed casp,
        uint256 notificationId,
        string newMemberName,
        uint256 startDate
    );
    event ManagementChangeAcknowledged(address indexed casp, uint256 notificationId);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _casps, address[] memory _ncas) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraph 1: Mandatory Notification
    function notifyManagementChange(
        address _caspAddress,
        string memory _newMemberName,
        uint256 _startDate,
        bytes32 _detailsHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(_startDate > block.timestamp, "Start date must be in the future");
        uint256 notificationId = casps[_caspAddress].managementChanges.length;
        casps[_caspAddress].managementChanges.push(ManagementChange({
            newMemberName: _newMemberName,
            startDate: _startDate,
            detailsHash: _detailsHash,
            submissionDate: block.timestamp,
            isAcknowledged: false,
            acknowledgmentDate: 0
        }));
        emit ManagementChangeNotified(_caspAddress, notificationId, _newMemberName, _startDate);
    }

    // Paragraph 1: NCA Acknowledgment
    function acknowledgeManagementChange(
        address _caspAddress,
        uint256 _notificationId
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        ManagementChange storage change = casps[_caspAddress].managementChanges[_notificationId];
        require(change.submissionDate > 0, "Change not notified");
        require(!change.isAcknowledged, "Already acknowledged");
        change.isAcknowledged = true;
        change.acknowledgmentDate = block.timestamp;
        emit ManagementChangeAcknowledged(_caspAddress, _notificationId);
    }
}