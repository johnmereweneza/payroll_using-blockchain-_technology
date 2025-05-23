TOPIC : Payroll Management System DApp
_______________

A decentralized payroll application (DApp) that allows employers to add employees, manage salary claims, and disburse payments using Ethereum smart contracts. Built with Solidity, React, Ethers.js, and MetaMask.

Table of Contents
_______

1. Overview
2. Features
3. Technologies Used
4. Getting Started : 
  A. Prerequisites
  B. Installation
  C. Deployment
  D. Running the Frontend

5. Smart Contract :
  A. Contract Structure
  B. Key Functions

6. Frontend Functionality](#frontend-functionality)
7. Screenshots
8. License


1. Overview
____

This DApp provides a simple way to manage payrolls on the Ethereum blockchain. It allows the employer to:
A. Add employees
B. Deposit ETH into the contract
C. Approve employee salary claims
D. Monitor pending claims and employee records

Employees can:
A.  Claim their salary based on daily pay and hours
B. Check their current balances
2. Features
_____

A. Role-based access: Owner vs Employee
B. Smart contract interaction via MetaMask
C. Salary claim and approval system
D. Real-time Ethereum balance checking
E. Full-stack implementation with React and Ethers.js
F. Bootstrap UI for clean layout


3. Technologies Used
________

- Solidity : for smart contract
- Hardhat : for local development
- React with : Bootstrap** for frontend
- Ethers.js : for Ethereum interaction
- MetaMask : for wallet connection


4. Getting Started
________

A. Prerequisites : 

- Node.js: https://nodejs.org/
- Hardhat: https://hardhat.org/
- MetaMask :https://metamask.io/

B. Installation

bash : 
git clone https://github.com/your-repo/payroll-dapp.git
cd payroll-dapp
npm install
🛠 Deployment
Compile and deploy the contract locally using Hardhat:

bash
Copy
Edit
npx hardhat compile
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost
Update the getPayrollContract function to connect to the deployed contract address.

Running the Frontend
In a new terminal:

bash
Copy
Edit
cd client
npm install
npm start
Then open: http://localhost:3000

 5. Smart Contract
 _______

 Contract Structure
File: contracts/Payroll.sol

solidity
Copy
Edit
struct Employee {
    address payable wallet;
    string name;
    uint256 dailyPay;
    uint256 hoursPerDay;
    bool isActive;
}

struct PendingClaim {
    uint256 amount;
    bool exists;
}
 Key Functions 
Function	Access	Description
addEmployee()	onlyOwner	Adds a new employee
claimSalary()	onlyEmployee	Employees claim salary
approveClaim()	onlyOwner	Approves and transfers salary
employeeList()	onlyOwner	Lists employee names
pendingClaims()	onlyOwner	Shows pending claims
deposit()	onlyOwner	Deposits ETH to the contract
getEmployee()	public	Returns details of an employee

6. Frontend Functionality :
___________

Employer Interface :

A. Add employees by wallet address and name

B. Deposit Ether to the contract

C. Approve pending claims

D. View list of employee names

E. View pending claim addresses
Employee Interface :
_________

A. Claim salary based on configured pay and hours
B. Check ETH balance via contract method

payrol.sol
_____

pragma solidity ^0.8.0;

contract Payroll {
    address public owner;

    struct Employee {
        address payable wallet;
        string name;
        uint256 hourlyPay; // stored in wei
        uint256 hoursPerDay;
        bool isActive;
    }

    struct PendingClaim {
        uint256 amount;
        bool exists;
    }

    mapping(address => Employee) private employees;
    mapping(address => PendingClaim) private claims;
    address[] private employeeAddresses;
    address[] private pendingAddresses;

    event EmployeeAdded(address indexed employee, string name, uint256 hourlyPay, uint256 hoursPerDay);
    event ClaimSubmitted(address indexed employee, uint256 amount);
    event ClaimApproved(address indexed employeeWallet, uint256 amount);
    event DepositReceived(address indexed sender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyEmployee() {
        require(employees[msg.sender].isActive, "Only registered employees");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable onlyOwner {
        emit DepositReceived(msg.sender, msg.value);
    }

    function addEmployee(
        address payable _employee,
        string memory _name,
        uint256 _hourlyPayInEther,
        uint256 _hoursPerDay
    ) external onlyOwner {
        require(_employee != address(0), "Invalid employee address");
        require(!employees[_employee].isActive, "Employee already exists");

        uint256 hourlyPayInWei = _hourlyPayInEther * 1 ether;

        employees[_employee] = Employee({
            wallet: _employee,
            name: _name,
            hourlyPay: hourlyPayInWei,
            hoursPerDay: _hoursPerDay,
            isActive: true
        });

        employeeAddresses.push(_employee);
        emit EmployeeAdded(_employee, _name, hourlyPayInWei, _hoursPerDay);
    }

    function getEmployee(address _addr)
        public view returns (
            address wallet,
            string memory name,
            uint256 hourlyPay,
            uint256 hoursPerDay,
            bool isActive
        )
    {
        Employee memory emp = employees[_addr];
        return (emp.wallet, emp.name, emp.hourlyPay, emp.hoursPerDay, emp.isActive);
    }

    function claimSalary() external onlyEmployee {
        require(!claims[msg.sender].exists, "Already have a pending claim");

        Employee memory emp = employees[msg.sender];
        uint256 amount = emp.hourlyPay * emp.hoursPerDay;

        claims[msg.sender] = PendingClaim(amount, true);
        pendingAddresses.push(msg.sender);

        emit ClaimSubmitted(msg.sender, amount);
    }

    function approveClaim(address _employee) external onlyOwner {
        PendingClaim memory claim = claims[_employee];
        require(claim.exists, "No pending claim");
        require(address(this).balance >= claim.amount, "Insufficient contract balance");

        address payable wallet = employees[_employee].wallet;
        require(wallet != address(0), "Invalid employee wallet");

        (bool sent, ) = wallet.call{value: claim.amount}("");
        require(sent, "Failed to send Ether");

        emit ClaimApproved(wallet, claim.amount);

        delete claims[_employee];

        for (uint i = 0; i < pendingAddresses.length; i++) {
            if (pendingAddresses[i] == _employee) {
                pendingAddresses[i] = pendingAddresses[pendingAddresses.length - 1];
                pendingAddresses.pop();
                break;
            }
        }
    }

    function pendingClaims() external view onlyOwner returns (address[] memory) {
        return pendingAddresses;
    }

    function employeeList() external view onlyOwner returns (string[] memory) {
        string[] memory names = new string[](employeeAddresses.length);
        for (uint i = 0; i < employeeAddresses.length; i++) {
            names[i] = employees[employeeAddresses[i]].name;
        }
        return names;
    }

    receive() external payable {
        emit DepositReceived(msg.sender, msg.value);
    }
}
#   p a y r o l l _ u s i n g - b l o c k c h a i n - _ t e c h n o l o g y  
 #   p a y r o l l _ u s i n g - b l o c k c h a i n - _ t e c h n o l o g y  
 