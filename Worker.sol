// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;


import '@openzeppelin/contracts/interfaces/IERC721Receiver.sol';
import '@openzeppelin/contracts/interfaces/IERC1155Receiver.sol';
import '@openzeppelin/contracts/interfaces/IERC721Enumerable.sol';


contract Worker is  IERC721Receiver, IERC1155Receiver  {
  address public _owner;

  modifier onlyOwner {
    require(msg.sender == _owner || tx.origin == _owner, "BAD_OWNER");
    _;
  }

  constructor(address owner)  {
    _owner = owner;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    require(_owner != newOwner, "INVALID_OWNER");
    _owner = newOwner;
  }

  function init(address owner) external {
    require(_owner == address(0), "owner is already setted!");
    _owner = owner;
  }

  function execTransaction(
    address payable target,
    bytes calldata input,
    uint256 value
  ) external payable onlyOwner {
    (bool succ, ) = target.call{value: value}(input);
    require(succ, 'EXEC_FAILED');
  }


  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4) external pure override returns (bool) {
    return true;
  }

  receive() external payable {}

  fallback() external payable {}

  function withdraw(address recipient) public onlyOwner {
        (bool success, ) = payable(recipient).call{
            value: address(this).balance
        }("");
        require(success, "WITHDRAWAL_FAILED");
  }

  function withdrawNFT721(address erc721_address, address recipient) external onlyOwner {
        IERC721Enumerable token = IERC721Enumerable(erc721_address);

        uint256 token_num = token.balanceOf(address(this));
        for (uint256 i = 0; i < token_num; i++) {
            if (token.balanceOf(address(this)) > 0) {
                //TODO : use call instead of interface
                // (bool success, bytes memory returnData) = target.call(bytes4(keccak256(abi.encodePacked("tokenOfOwnerByIndex(address,uint256)")),address(this), i));
                // require(success);
                uint256 tokenId = token.tokenOfOwnerByIndex(address(this), 0);
                require(
                    token.ownerOf(tokenId) == address(this),
                    "You must own the token"
                );
                token.transferFrom(address(this), recipient, tokenId);
            }
        }
    }
}
