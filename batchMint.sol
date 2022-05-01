// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Deployed {

    function tokenOfOwnerByIndex(address user, uint256 id)
        public
        view
        returns (uint256)
    {}
}

contract contractMint is IERC721Receiver, Ownable {
    
    event log(address user, uint256 id);

    constructor() payable {
    
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        return 0x150b7a02;
    }
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }


    function mint(address target, uint256 value, bytes memory optCode) external payable onlyOwner {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, ) = target.call{value: value}(optCode); // D's storage is set, E is not modified
        require(success);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdraw(address recipient) public onlyOwner {
        (bool success, ) = payable(recipient).call{
            value: address(this).balance
        }("");
        require(success, "WITHDRAWAL_FAILED");
    }

    function withdrawNFT(address erc721_address, address recipient) external onlyOwner {
        ERC721 token = ERC721(erc721_address);
        Deployed dc = Deployed(erc721_address);
        uint256 token_num = token.balanceOf(address(this));
        for (uint256 i = 0; i < token_num; i++) {
            if (token.balanceOf(address(this)) > 0) {
                //TODO : use call instead of interface
                // (bool success, bytes memory returnData) = target.call(bytes4(keccak256(abi.encodePacked("tokenOfOwnerByIndex(address,uint256)")),address(this), i));
                // require(success);
                uint256 tokenId = dc.tokenOfOwnerByIndex(address(this), 0);
                require(
                    token.ownerOf(tokenId) == address(this),
                    "You must own the token"
                );
                token.transferFrom(address(this), recipient, tokenId);
            }
        }
    }
}

contract mintFactory is Ownable {
    contractMint[] public _mint;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant NFT_PRICE = 0.001 ether;
    uint256 public constant MAX_PER_WALLET = 2;

    function createMint() external payable {
        contractMint mintContract = new contractMint{
            value: (MAX_PER_WALLET) * NFT_PRICE
        }();
        _mint.push(mintContract);
    }

    function createBatchMint(uint256 _num)
        external
        payable
        onlyOwner
    {
        require(
            msg.value >= (MAX_PER_WALLET) * NFT_PRICE * _num,
            "Not enough eth to pay"
        );
        for (uint256 i = 0; i < _num; i++) {
            this.createMint();
        }
    }

    function batchMintStart(address target, uint256 value, bytes memory optCode) external onlyOwner {
        for (uint256 i = 0; i < _mint.length; i++) {
            _mint[i].mint(target, value, optCode);
        }
    }

    function batchWithdraw(address erc721_address, address recipient) external onlyOwner {
        for (uint256 i = 0; i < _mint.length; i++) {
            _mint[i].withdraw(recipient);
            _mint[i].withdrawNFT(erc721_address, recipient);
        }
    }
}
