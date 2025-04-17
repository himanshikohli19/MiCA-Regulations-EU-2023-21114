// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 70
contract CASPSafekeepingRegistry {
    struct CryptoSafekeeping {
        bytes32 safekeepingMechanismHash;  // e.g., cold storage, multi-sig details
        uint256 submissionDate;
    }

    struct FiatSafekeeping {
        bytes32 fiatAccountHash;  // Separate account details
        uint256 depositTimestamp;
        uint256 submissionDate;
    }

    struct PaymentServices {
        bool isPSDAuthorized;  // PSD2 compliance
        bytes32 disclosureHash;  // Terms, laws, third-party info
        bool usesThirdParty;
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        bool isExempt;  // EMI, PI, or bank
        CryptoSafekeeping cryptoSafekeeping;
        FiatSafekeeping fiatSafekeeping;
        PaymentServices paymentServices;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    mapping(address => bool) public ncAuthority;

    event CryptoSafekeepingMechanismSubmitted(address indexed casp);
    event FiatSafekeepingSubmitted(address indexed casp, uint256 depositTimestamp);
    event PaymentServiceDetailsSubmitted(address indexed casp, bool isPSDAuthorized);
    event ExemptionRegistered(address indexed casp, bool isExempt);

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

    // Paragraph 1: Safeguarding Clients’ Crypto-Assets
    function submitCryptoSafekeepingMechanism(
        address _caspAddress,
        bytes32 _safekeepingMechanismHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(!casps[_caspAddress].isExempt, "CASP is exempt from safekeeping rules");
        casps[_caspAddress].cryptoSafekeeping = CryptoSafekeeping({
            safekeepingMechanismHash: _safekeepingMechanismHash,
            submissionDate: block.timestamp
        });
        emit CryptoSafekeepingMechanismSubmitted(_caspAddress);
    }

    // Paragraphs 2 & 3: Safeguarding Clients’ Fiat Funds
    function submitFiatSafekeeping(
        address _caspAddress,
        bytes32 _fiatAccountHash,
        uint256 _depositTimestamp
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(!casps[_caspAddress].isExempt, "CASP is exempt from safekeeping rules");
        require(_depositTimestamp <= block.timestamp + 1 days, "Deposit must be by next day");
        casps[_caspAddress].fiatSafekeeping = FiatSafekeeping({
            fiatAccountHash: _fiatAccountHash,
            depositTimestamp: _depositTimestamp,
            submissionDate: block.timestamp
        });
        emit FiatSafekeepingSubmitted(_caspAddress, _depositTimestamp);
    }

    // Paragraph 4: Payment Services
    function submitPaymentServiceDetails(
        address _caspAddress,
        bool _isPSDAuthorized,
        bytes32 _disclosureHash,
        bool _usesThirdParty
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(!casps[_caspAddress].isExempt, "CASP is exempt from safekeeping rules");
        casps[_caspAddress].paymentServices = PaymentServices({
            isPSDAuthorized: _isPSDAuthorized,
            disclosureHash: _disclosureHash,
            usesThirdParty: _usesThirdParty,
            submissionDate: block.timestamp
        });
        emit PaymentServiceDetailsSubmitted(_caspAddress, _isPSDAuthorized);
    }

    // Paragraph 5: Exemptions
    function registerExemption(
        address _caspAddress,
        bool _isExempt
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].isExempt = _isExempt;
        emit ExemptionRegistered(_caspAddress, _isExempt);
    }
}