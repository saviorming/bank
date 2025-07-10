```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 管理员地址
    address public admin;
    
    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;
    
    // 记录存款金额前三名的用户
    address[3] public topDepositors;
    
    // 事件：存款
    event Deposited(address indexed user, uint256 amount);
    // 事件：提款
    event Withdrawn(address indexed admin, uint256 amount);
    
    // 构造函数，设置管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 修饰器：仅管理员可调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }
    
    // 接收以太币的函数
    receive() external payable {
        deposit();
    }
    
    // 存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        // 更新前三名存款用户
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // 更新前三名存款用户
    function updateTopDepositors(address user, uint256 newBalance) internal {
        // 检查用户是否已经在前三名中
        bool alreadyInTop = false;
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] == user) {
                alreadyInTop = true;
                break;
            }
        }
        
        // 如果用户不在前三名中，或者已经在其中，都需要重新排序
        for (uint i = 0; i < 3; i++) {
            // 如果当前位为空，直接放入
            if (topDepositors[i] == address(0)) {
                topDepositors[i] = user;
                break;
            }
            // 如果新余额大于当前位置的余额，插入并后移其他用户
            else if (newBalance > balances[topDepositors[i]]) {
                // 如果用户不在当前top中，需要把最后一位移除
                if (!alreadyInTop) {
                    for (uint j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j - 1];
                    }
                } else {
                    // 如果用户已经在top中，需要更复杂的处理
                    // 这里简化为重新排序整个数组
                    _sortTopDepositors();
                    return;
                }
                topDepositors[i] = user;
                break;
            }
        }
        
        // 确保数组排序正确
        _sortTopDepositors();
    }
    
    // 对前三名存款用户进行排序
    function _sortTopDepositors() internal {
        // 这里只能用冒泡，正常情况应该很耗费gas，老师上课说不建议用循环
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                if (balances[topDepositors[j]] < balances[topDepositors[j + 1]]) {
                    address temp = topDepositors[j];
                    topDepositors[j] = topDepositors[j + 1];
                    topDepositors[j + 1] = temp;
                }
            }
        }
    }
    
    // 管理员提款函数
    function withdraw(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "Insufficient contract balance");
        
        // 转账给管理员
        payable(admin).transfer(amount);
        
        emit Withdrawn(admin, amount);
    }
    
    // 获取合约总余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // 获取前三名存款用户及其余额
    function getTopDepositors() external view returns (address[3] memory, uint256[3] memory) {
        uint256[3] memory topBalances;
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                topBalances[i] = balances[topDepositors[i]];
            }
        }
        return (topDepositors, topBalances);
    }
}
```