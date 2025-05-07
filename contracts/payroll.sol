// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// contract Payroll {
//     address public owner;

//     struct Employee {
//         address payable wallet;
//         string name;
//         uint256 dailyPay;
//         uint256 hoursPerDay;
//         bool isActive;
//     }

//     struct PendingClaim {
//         uint256 amount;
//         bool exists;
//     }


//     mapping(address => Employee) private employees;
//     mapping(address => PendingClaim) private claims;
//     address[] private employeeAddresses;
//     address[] private pendingAddresses;

//     modifier onlyOwner() {
//         require(msg.sender == owner, "Only owner can perform this action");
//         _;
//     }

//     modifier onlyEmployee() {
//         require(employees[msg.sender].isActive, "Only registered employees");
//         _;
//     }

//     constructor() {
//         owner = msg.sender;
//     }

//     function deposit() external payable onlyOwner {}

//     function addEmployee(
//         address payable _employee,
//         string memory _name,
//         uint256 _dailyPay,
//         uint256 _hoursPerDay
//     ) external onlyOwner {
//         require(!employees[_employee].isActive, "Employee already exists");

//         employees[_employee] = Employee({
//             wallet: _employee,
//             name: _name,
//             dailyPay: _dailyPay,
//             hoursPerDay: _hoursPerDay,
//             isActive: true
//         });

//         employeeAddresses.push(_employee);
//     }

//     function claimSalary() external onlyEmployee {
//         require(!claims[msg.sender].exists, "Already have a pending claim");

//         Employee memory emp = employees[msg.sender];
//         uint256 amount = emp.dailyPay * emp.hoursPerDay;

//         claims[msg.sender] = PendingClaim(amount, true);
//         pendingAddresses.push(msg.sender);
//     }

//     function approveClaim(address payable _employee) external onlyOwner {
//         PendingClaim memory claim = claims[_employee];
//         require(claim.exists, "No pending claim");
//         require(address(this).balance >= claim.amount, "Insufficient contract balance");

//         _employee.transfer(claim.amount);
//         delete claims[_employee];

//         for (uint i = 0; i < pendingAddresses.length; i++) {
//             if (pendingAddresses[i] == _employee) {
//                 pendingAddresses[i] = pendingAddresses[pendingAddresses.length - 1];
//                 pendingAddresses.pop();
//                 break;
//             }
//         }
//     }

//     function pendingClaims() external view onlyOwner returns (address[] memory) {
//         return pendingAddresses;
//     }

//     function employeeList() external view onlyOwner returns (string[] memory) {
//         string[] memory names = new string[](employeeAddresses.length);
//         for (uint i = 0; i < employeeAddresses.length; i++) {
//             names[i] = employees[employeeAddresses[i]].name;
//         }
//         return names;
//     }

//     receive() external payable {}
// }



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
