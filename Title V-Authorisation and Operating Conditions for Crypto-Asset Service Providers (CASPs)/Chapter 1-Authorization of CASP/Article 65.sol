// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPPassportingRegistry {
    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    struct Passporting {
        uint256 notificationDate;
        string[] targetMemberStates;
        CryptoService[] services;
        uint256 plannedStartDate;
        string nonMiCAActivities;
        bool isNotified;
        bool isConfirmed;
    }

    struct CASP {
        address caspAddress;
        bool isAuthorized;
        string memberState;
        Passporting passporting;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public ncAuthority;

    event CrossBorderNotified(
        address indexed casp,
        string[] targetMemberStates,
        CryptoService[] services,
        uint256 plannedStartDate
    );

    event NCACommunicationConfirmed(address indexed casp, string[] targetMemberStates);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint256 i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraph 1: Notification Requirement
    function notifyCrossBorder(
        address _caspAddress,
        string[] memory _targetMemberStates,
        CryptoService[] memory _services,
        uint256 _plannedStartDate,
        string memory _nonMiCAActivities
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(_targetMemberStates.length > 0, "Must specify target states");
        require(_plannedStartDate > block.timestamp, "Start date must be in the future");

        casps[_caspAddress].passporting = Passporting({
            notificationDate: block.timestamp,
            targetMemberStates: _targetMemberStates,
            services: _services,
            plannedStartDate: _plannedStartDate,
            nonMiCAActivities: _nonMiCAActivities,
            isNotified: false,
            isConfirmed: false
        });

        emit CrossBorderNotified(_caspAddress, _targetMemberStates, _services, _plannedStartDate);
    }

    // Paragraphs 2-3: NCA Communication
    function confirmNCACommunication(address _caspAddress) external onlyNCA {
        Passporting storage passporting = casps[_caspAddress].passporting;
        require(passporting.notificationDate > 0, "No passporting notification");
        require(
            block.timestamp <= passporting.notificationDate + 10 days,
            "10-day communication period expired"
        );

        passporting.isNotified = true;
        passporting.isConfirmed = true;

        emit NCACommunicationConfirmed(_caspAddress, passporting.targetMemberStates);
    }

    // Paragraph 4: Timeline for Launch
    function canStartCrossBorder(address _caspAddress) public view returns (bool) {
        Passporting storage passporting = casps[_caspAddress].passporting;
        if (passporting.notificationDate == 0) return false;

        return (
            (passporting.isConfirmed && block.timestamp >= passporting.plannedStartDate) ||
            (block.timestamp >= passporting.notificationDate + 15 days)
        );
    }

    // Check if CASP can operate in the given state
    function canOperateInState(address _caspAddress, string memory _state) public view returns (bool) {
        if (!casps[_caspAddress].isAuthorized || !canStartCrossBorder(_caspAddress)) return false;

        Passporting storage passporting = casps[_caspAddress].passporting;

        if (
            keccak256(bytes(casps[_caspAddress].memberState)) ==
            keccak256(bytes(_state))
        ) {
            return true;
        }

        for (uint256 i = 0; i < passporting.targetMemberStates.length; i++) {
            if (
                keccak256(bytes(passporting.targetMemberStates[i])) ==
                keccak256(bytes(_state))
            ) {
                return true;
            }
        }

        return false;
    }
}