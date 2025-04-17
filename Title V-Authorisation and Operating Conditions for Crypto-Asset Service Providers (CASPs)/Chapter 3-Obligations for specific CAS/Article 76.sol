// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPTradingPlatformRegistry {
    struct OperatingRules {
        bytes32 rulesHash;
        uint256 submissionDate;
    }

    struct AssetSuitability {
        bytes32 assessmentHash;
        uint256 submissionDate;
    }

    struct ProprietaryTradingBan {
        bytes32 commitmentHash;
        uint256 submissionDate;
    }

    struct MatchedPrincipalTrading {
        bytes32 consentHash;
        uint256 submissionDate;
    }

    struct ResiliencePlan {
        bytes32 planHash;
        uint256 submissionDate;
    }

    struct MarketAbuseReport {
        bytes32 reportHash;
        uint256 submissionDate;
    }

    struct PricingData {
        bytes32 pricingHash;
        uint256 submissionDate;
    }

    struct SettlementRecord {
        bytes32 settlementHash;
        uint256 settlementTime;
        uint256 submissionDate;
    }

    struct FeeStructure {
        bytes32 feeHash;
        uint256 submissionDate;
    }

    struct OrderBookRecord {
        bytes32 orderBookHash;
        uint256 submissionDate;
        uint256 expirationDate;
    }

    struct CASP {
        bool isAuthorized;
        OperatingRules operatingRules;
        mapping(string => AssetSuitability) assetSuitability;
        ProprietaryTradingBan proprietaryTradingBan;
        MatchedPrincipalTrading matchedPrincipalTrading;
        ResiliencePlan resiliencePlan;
        MarketAbuseReport[] marketAbuseReports;
        PricingData pricingData;
        SettlementRecord[] settlementRecords;
        FeeStructure feeStructure;
        OrderBookRecord[] orderBookRecords;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    address public esmaAuthority;
    bytes32 public rtsStandardsHash;

    event OperatingRulesSubmitted(address indexed casp);
    event AssetSuitabilitySubmitted(address indexed casp, string assetId);
    event ProprietaryTradingBanSubmitted(address indexed casp);
    event MatchedPrincipalTradingSubmitted(address indexed casp);
    event ResiliencePlanSubmitted(address indexed casp);
    event MarketAbuseReported(address indexed casp);
    event PricingDataSubmitted(address indexed casp);
    event SettlementRecordSubmitted(address indexed casp);
    event FeeStructureSubmitted(address indexed casp);
    event OrderBookRecordSubmitted(address indexed casp);
    event RTSStandardsUpdated(bytes32 rtsHash);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyESMA() {
        require(msg.sender == esmaAuthority, "Only ESMA can call this function");
        _;
    }

    constructor(address[] memory _casps, address _esma) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        esmaAuthority = _esma;
    }

    // Paragraph 1: Operating Rules
    function submitOperatingRules(address _caspAddress, bytes32 _rulesHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].operatingRules = OperatingRules({
            rulesHash: _rulesHash,
            submissionDate: block.timestamp
        });
        emit OperatingRulesSubmitted(_caspAddress);
    }

    // Paragraph 2: Suitability Assessment
    function submitAssetSuitability(address _caspAddress, string memory _assetId, bytes32 _assessmentHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].assetSuitability[_assetId] = AssetSuitability({
            assessmentHash: _assessmentHash,
            submissionDate: block.timestamp
        });
        emit AssetSuitabilitySubmitted(_caspAddress, _assetId);
    }

    // Paragraph 5: Proprietary Trading Ban
    function submitProprietaryTradingBan(address _caspAddress, bytes32 _commitmentHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].proprietaryTradingBan = ProprietaryTradingBan({
            commitmentHash: _commitmentHash,
            submissionDate: block.timestamp
        });
        emit ProprietaryTradingBanSubmitted(_caspAddress);
    }

    // Paragraph 6: Matched Principal Trading
    function submitMatchedPrincipalTrading(address _caspAddress, bytes32 _consentHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].matchedPrincipalTrading = MatchedPrincipalTrading({
            consentHash: _consentHash,
            submissionDate: block.timestamp
        });
        emit MatchedPrincipalTradingSubmitted(_caspAddress);
    }

    // Paragraph 7: Trading System Resilience
    function submitResiliencePlan(address _caspAddress, bytes32 _planHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].resiliencePlan = ResiliencePlan({
            planHash: _planHash,
            submissionDate: block.timestamp
        });
        emit ResiliencePlanSubmitted(_caspAddress);
    }

    // Paragraph 8: Market Abuse Reporting
    function reportMarketAbuse(address _caspAddress, bytes32 _reportHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].marketAbuseReports.push(MarketAbuseReport({
            reportHash: _reportHash,
            submissionDate: block.timestamp
        }));
        emit MarketAbuseReported(_caspAddress);
    }

    // Paragraphs 9-11: Transparency in Pricing
    function submitPricingData(address _caspAddress, bytes32 _pricingHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].pricingData = PricingData({
            pricingHash: _pricingHash,
            submissionDate: block.timestamp
        });
        emit PricingDataSubmitted(_caspAddress);
    }

    // Paragraph 12: Settlement Deadlines
    function submitSettlementRecord(address _caspAddress, bytes32 _settlementHash, uint256 _settlementTime) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(_settlementTime <= block.timestamp + 1 days, "Settlement must be within 24 hours");
        casps[_caspAddress].settlementRecords.push(SettlementRecord({
            settlementHash: _settlementHash,
            settlementTime: _settlementTime,
            submissionDate: block.timestamp
        }));
        emit SettlementRecordSubmitted(_caspAddress);
    }

    // Paragraph 13: Fair Fee Structures
    function submitFeeStructure(address _caspAddress, bytes32 _feeHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].feeStructure = FeeStructure({
            feeHash: _feeHash,
            submissionDate: block.timestamp
        });
        emit FeeStructureSubmitted(_caspAddress);
    }

    // Paragraph 15: Order Book Record-Keeping
    function submitOrderBookRecord(address _caspAddress, bytes32 _orderBookHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].orderBookRecords.push(OrderBookRecord({
            orderBookHash: _orderBookHash,
            submissionDate: block.timestamp,
            expirationDate: block.timestamp + 5 * 365 days
        }));
        emit OrderBookRecordSubmitted(_caspAddress);
    }

    // Paragraph 16: ESMA Technical Standards
    function updateRTSStandards(bytes32 _rtsHash) external onlyESMA {
        rtsStandardsHash = _rtsHash;
        emit RTSStandardsUpdated(_rtsHash);
    }
}