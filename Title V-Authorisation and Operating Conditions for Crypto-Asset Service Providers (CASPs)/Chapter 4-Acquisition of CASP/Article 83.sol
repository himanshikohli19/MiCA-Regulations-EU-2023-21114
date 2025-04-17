// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPAcquisitionAssessment {
    struct Acquisition {
        address caspAddress;
        address acquirerAddress;
        uint256 intendedHoldingPercentage;
        bytes32 rtsInfoHash;
        uint256 notificationDate;
        bool isAcknowledged;
        uint256 acknowledgmentDate;
        bool isApproved;
        bool isOpposed;
        string oppositionReason;
        uint256 assessmentExpiryDate;
        bool isSuspended;
        uint256 suspensionStart;
        uint256 suspensionEnd;
        bytes32 consultationProof;
        bytes32 additionalInfoHash;
        uint256 completionDeadline;
    }

    struct Disposal {
        address caspAddress;
        address sellerAddress;
        uint256 currentHoldingPercentage;
        uint256 reducedHoldingPercentage;
        uint256 notificationDate;
    }

    struct CASP {
        bool isAuthorized;
    }

    mapping(address => CASP) public casps;
    mapping(address => Acquisition) public acquisitions;
    mapping(address => Disposal) public disposals;
    mapping(address => bool) public ncAuthority;

    event AcquisitionNotified(address indexed casp, address indexed acquirer, uint256 percentage);
    event DisposalNotified(address indexed casp, address indexed seller, uint256 reducedPercentage);
    event ReceiptAcknowledged(address indexed acquirer, uint256 expiryDate);
    event ConsultationSubmitted(address indexed acquirer);
    event AdditionalInfoRequested(address indexed acquirer, string infoType);
    event AdditionalInfoSubmitted(address indexed acquirer);
    event AcquisitionOpposed(address indexed acquirer, string reason);
    event AcquisitionApproved(address indexed acquirer);
    event CompletionDeadlineSet(address indexed acquirer, uint256 deadline);
    event CompletionDeadlineExtended(address indexed acquirer, uint256 newDeadline);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraph 1: Notify Acquisition
    function notifyAcquisition(
        address _caspAddress,
        address _acquirerAddress,
        uint256 _intendedHoldingPercentage,
        bytes32 _rtsInfoHash
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(_intendedHoldingPercentage >= 20, "Holding must be 20% or more");
        acquisitions[_acquirerAddress] = Acquisition({
            caspAddress: _caspAddress,
            acquirerAddress: _acquirerAddress,
            intendedHoldingPercentage: _intendedHoldingPercentage,
            rtsInfoHash: _rtsInfoHash,
            notificationDate: block.timestamp,
            isAcknowledged: false,
            acknowledgmentDate: 0,
            isApproved: false,
            isOpposed: false,
            oppositionReason: "",
            assessmentExpiryDate: 0,
            isSuspended: false,
            suspensionStart: 0,
            suspensionEnd: 0,
            consultationProof: bytes32(0),
            additionalInfoHash: bytes32(0),
            completionDeadline: 0
        });
        emit AcquisitionNotified(_caspAddress, _acquirerAddress, _intendedHoldingPercentage);
    }

    // Paragraph 2: Notify Disposal
    function notifyDisposal(
        address _caspAddress,
        address _sellerAddress,
        uint256 _currentHoldingPercentage,
        uint256 _reducedHoldingPercentage
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(_currentHoldingPercentage > _reducedHoldingPercentage, "Invalid reduction");
        disposals[_sellerAddress] = Disposal({
            caspAddress: _caspAddress,
            sellerAddress: _sellerAddress,
            currentHoldingPercentage: _currentHoldingPercentage,
            reducedHoldingPercentage: _reducedHoldingPercentage,
            notificationDate: block.timestamp
        });
        emit DisposalNotified(_caspAddress, _sellerAddress, _reducedHoldingPercentage);
    }

    // Paragraph 3: Acknowledge Receipt
    function acknowledgeReceipt(address _acquirerAddress) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.notificationDate > 0, "No acquisition notified");
        require(block.timestamp <= acq.notificationDate + 2 days, "2-day acknowledgment period expired");
        acq.isAcknowledged = true;
        acq.acknowledgmentDate = block.timestamp;
        acq.assessmentExpiryDate = block.timestamp + 60 days;
        emit ReceiptAcknowledged(_acquirerAddress, acq.assessmentExpiryDate);
    }

    // Paragraph 5: Consultation
    function submitConsultationProof(
        address _acquirerAddress,
        bytes32 _consultationHash
    ) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.isAcknowledged, "Receipt not acknowledged");
        acq.consultationProof = _consultationHash;
        emit ConsultationSubmitted(_acquirerAddress);
    }

    // Paragraph 6: Additional Info
    function requestAdditionalInfo(
        address _acquirerAddress,
        string memory _infoType,
        bool _isNonEUAcquirer
    ) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.isAcknowledged, "Receipt not acknowledged");
        require(block.timestamp <= acq.acknowledgmentDate + 50 days,
            "Request must be before Day 50");
        acq.isSuspended = true;
        acq.suspensionStart = block.timestamp;
        acq.suspensionEnd = block.timestamp + (_isNonEUAcquirer ? 30 days : 20 days);
        emit AdditionalInfoRequested(_acquirerAddress, _infoType);
    }

    function submitAdditionalInfo(
        address _acquirerAddress,
        bytes32 _infoHash
    ) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.isSuspended, "Assessment not suspended");
        require(block.timestamp <= acq.suspensionEnd, "Suspension period expired");
        acq.additionalInfoHash = _infoHash;
        uint256 suspensionDuration = block.timestamp - acq.suspensionStart;
        acq.assessmentExpiryDate += suspensionDuration;
        acq.isSuspended = false;
        emit AdditionalInfoSubmitted(_acquirerAddress);
    }

    // Paragraph 7: Oppose Acquisition
    function opposeAcquisition(
        address _acquirerAddress,
        string memory _reason
    ) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.isAcknowledged && !acq.isSuspended, "Invalid state for decision");
        require(block.timestamp <= acq.assessmentExpiryDate, "Assessment period expired");
        acq.isOpposed = true;
        acq.oppositionReason = _reason;
        emit AcquisitionOpposed(_acquirerAddress, _reason);
    }

    // Paragraph 8: Automatic Approval
    function checkApprovalStatus(address _acquirerAddress) public view returns (bool) {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        if (!acq.isAcknowledged || acq.isOpposed) return false;
        if (block.timestamp > acq.assessmentExpiryDate && !acq.isApproved) {
            return true; // Deemed approved
        }
        return acq.isApproved;
    }

    function finalizeApproval(address _acquirerAddress) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(checkApprovalStatus(_acquirerAddress), "Not eligible for approval");
        acq.isApproved = true;
        emit AcquisitionApproved(_acquirerAddress);
    }

    // Paragraph 9: Completion Deadline
    function setCompletionDeadline(
        address _acquirerAddress,
        uint256 _deadline
    ) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.isApproved, "Acquisition not approved");
        acq.completionDeadline = _deadline;
        emit CompletionDeadlineSet(_acquirerAddress, _deadline);
    }

    function extendCompletionDeadline(
        address _acquirerAddress,
        uint256 _newDeadline
    ) external onlyNCA {
        Acquisition storage acq = acquisitions[_acquirerAddress];
        require(acq.isApproved && acq.completionDeadline > 0, "No deadline set");
        require(_newDeadline > acq.completionDeadline, "Must extend deadline");
        acq.completionDeadline = _newDeadline;
        emit CompletionDeadlineExtended(_acquirerAddress, _newDeadline);
    }
}