// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Worker.sol";

contract mintFactory is Ownable {
    Worker[] public _workers;
    
    function createMint() external {
        Worker wroker = new Worker(msg.sender);
        _workers.push(wroker);
    }

    function cloneMint(address masterContract)
     public  onlyOwner returns(address  cloneAddress){
            require(masterContract != address(0), " No masterContract");
            
            cloneAddress = Clones.clone(masterContract);
            Worker worker = Worker(payable(cloneAddress));
            worker.init(msg.sender);
            _workers.push(worker);
        }

    function createBatchMint(uint256 _num, address masterContract)
        external
        onlyOwner{
        for (uint256 i = 0; i < _num; i++) {
            cloneMint(masterContract);
        }
    }

    

    function batchMintOpt(address payable target,  bytes memory optCode, uint256 valuePerWallet, uint256 walletNumber ) public  payable onlyOwner {
        require(_workers.length>=walletNumber&&walletNumber>0, "not right walletNumber!");
        require(msg.value>=valuePerWallet*walletNumber, "not ength money");
        for (uint256 i = 0; i < walletNumber; i++) {
            _workers[i].execTransaction{value: valuePerWallet}(target, optCode, valuePerWallet);
        }
    }

    
    function batchWithdrawAll(address erc721_address, address recipient) external onlyOwner {
        for (uint256 i = 0; i < _workers.length; i++) {
            _workers[i].withdraw(recipient);
            _workers[i].withdrawNFT721(erc721_address, recipient);
        }
    }

    function batchWithdrawNFT(address erc721_address, address recipient) external onlyOwner {
        for (uint256 i = 0; i < _workers.length; i++) {
            _workers[i].withdrawNFT721(erc721_address, recipient);
        }
    }

    function batchWithdrawMoney(address recipient) external onlyOwner {
        for (uint256 i = 0; i < _workers.length; i++) {
            _workers[i].withdraw(recipient);
        }
    }


    function getContractNum()external onlyOwner view returns(uint256){
        return _workers.length;
    }
}