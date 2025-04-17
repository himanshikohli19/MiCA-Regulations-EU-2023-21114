// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SignificantCASPRegistry {
    struct SupervisoryUpdate {
        uint256 updateDate;
        bytes32 updateHash;
        bool isAnnual;
    }

    struct CASP {
        bool isAuthorized;
        uint256 averageActiveUsers;
        uint256 lastUserReportDate;
        bool isSignificantPending;
        bool isSignificant;
        uint256 significantNotificationDate;
        uint256 lastAnnualUpdate;
        SupervisoryUpdate[] supervisoryUpdates;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public ncAuthority;
    mapping(address => bool) public caspAuthority;
    address public esmaAuthority;

    event ActiveUsersReported(address indexed casp, uint256 averageActiveUsers);
    event SignificantStatusNotified(address indexed casp);
    event SignificantStatusConfirmed(address indexed casp);
    event SupervisoryUpdateSubmitted(address indexed casp, bytes32 updateHash, bool isAnnual);
    event ExchangeOfViewsLogged(address indexed casp, bytes32 discussionHash);
    event ESMAPowerActionRecorded(address indexed casp, string actionType, bytes32 actionHash);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    modifier onlyESMA() {
        require(msg.sender == esmaAuthority, "Only ESMA can call this function");
        _;
    }

    constructor(address[] memory _ncas, address[] memory _casps, address _esma) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        esmaAuthority = _esma;
    }

    // Paragraph 1: Report Active Users
    function reportActiveUsers(
        address _caspAddress,
        uint256 _averageActiveUsers
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(_averageActiveUsers > 0, "Invalid user count");
        casps[_caspAddress].averageActiveUsers = _averageActiveUsers;
        casps[_caspAddress].lastUserReportDate = block.timestamp;
        if (_averageActiveUsers >= 15_000_000) {
            casps[_caspAddress].isSignificantPending = true;
        }
        emit ActiveUsersReported(_caspAddress, _averageActiveUsers);
    }

    // Paragraph 2: Notify Significant Status
    function notifySignificantStatus(address _caspAddress) external onlyCASP {
        CASP storage casp = casps[_caspAddress];
        require(casp.isSignificantPending, "CASP not pending significant status");
        require(block.timestamp <= casp.lastUserReportDate + 60 days,
            "2-month notification period expired");
        casp.significantNotificationDate = block.timestamp;
        emit SignificantStatusNotified(_caspAddress);
    }

    function confirmSignificantStatus(address _caspAddress) external onlyNCA {
        CASP storage casp = casps[_caspAddress];
        require(casp.isSignificantPending && casp.significantNotificationDate > 0,
            "CASP not notified as significant");
        casp.isSignificant = true;
        casp.isSignificantPending = false;
        emit SignificantStatusConfirmed(_caspAddress);
    }

    // Paragraph 3: Supervisory Updates
    function submitAnnualSupervisoryUpdate(
        address _caspAddress,
        bytes32 _updateHash
    ) external onlyNCA {
        CASP storage casp = casps[_caspAddress];
        require(casp.isSignificant, "CASP not significant");
        require(block.timestamp >= casp.lastAnnualUpdate + 365 days || casp.lastAnnualUpdate == 0,
            "Annual update already submitted this year");
        casp.lastAnnualUpdate = block.timestamp;
        casp.supervisoryUpdates.push(SupervisoryUpdate({
            updateDate: block.timestamp,
            updateHash: _updateHash,
            isAnnual: true
        }));
        emit SupervisoryUpdateSubmitted(_caspAddress, _updateHash, true);
    }

    function submitOptionalSupervisoryUpdate(
        address _caspAddress,
        bytes32 _updateHash
    ) external onlyNCA {
        CASP storage casp = casps[_caspAddress];
        require(casp.isSignificant, "CASP not significant");
        casp.supervisoryUpdates.push(SupervisoryUpdate({
            updateDate: block.timestamp,
            updateHash: _updateHash,
            isAnnual: false
        }));
        emit SupervisoryUpdateSubmitted(_caspAddress, _updateHash, false);
    }

    // Paragraph 4: Exchange of Views
    function logExchangeOfViews(
        address _caspAddress,
        bytes32 _discussionHash
    ) external onlyESMA {
        CASP storage casp = casps[_caspAddress];
        require(casp.isSignificant, "CASP not significant");
        emit ExchangeOfViewsLogged(_caspAddress, _discussionHash);
    }

    // Paragraph 5: ESMA Powers
    function recordESMAPowerAction(
        address _caspAddress,
        string memory _actionType,
        bytes32 _actionHash
    ) external onlyESMA {
        CASP storage casp = casps[_caspAddress];
        require(casp.isSignificant, "CASP not significant");
        emit ESMAPowerActionRecorded(_caspAddress, _actionType, _actionHash);
    }
}