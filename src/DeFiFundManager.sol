// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

contract DeFiFundManager is ERC20, Ownable {
    IERC20 public immutable stableToken;
    IStrategy[] public strategies;
    mapping(address => uint256) public userDeposits;

    uint256 private cachedTotalFunds;
    bool private cacheValid;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint256 amount);
    event StrategyAdded(address strategy);
    event RewardsCollected(uint256 totalRewards);

    constructor(address _stableToken, address initialOwner) ERC20("DeFi LP Token", "DFLP") Ownable(initialOwner) {
        require(_stableToken != address(0), "Stable token address cannot be zero");
        stableToken = IERC20(_stableToken);
        cacheValid = false;
    }

    /**
     * @notice Deposit stable tokens and receive LP tokens.
     * @param amount The amount of stable token to deposit.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Check allowance before transferring tokens
        uint256 allowance = stableToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient token allowance");

        // Transfer stable tokens to the contract
        stableToken.transferFrom(msg.sender, address(this), amount);

        // Mint LP tokens proportionally
        uint256 totalFunds = getTotalFunds();
        uint256 lpTokens = totalSupply() > 0 ? (amount * totalSupply()) / totalFunds : amount;
        _mint(msg.sender, lpTokens);

        // Update user deposit balance
        userDeposits[msg.sender] += amount;

        cacheValid = false;
        
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw stable tokens by burning LP tokens.
     * @param lpAmount The amount lf LP tokens to burn.
     */
    function withdraw(uint256 lpAmount) external {
        require(lpAmount > 0, "LP amount must be greater than 0");
        require(balanceOf(msg.sender) >= lpAmount, "Insufficient LP tokens");

        // Calculate the proporcional withdrawal amount
        uint256 totalFunds = getTotalFunds();
        uint256 withdrawalAmount = (lpAmount * totalFunds) / totalSupply();

        // Burn LP tokens
        _burn(msg.sender, lpAmount);

        // Update user deposit balance
        userDeposits[msg.sender] -= withdrawalAmount;

        // Transfer stable tokens to the user
        stableToken.transfer(msg.sender, withdrawalAmount);

        cacheValid = false;

        emit Withdraw(msg.sender, withdrawalAmount);
    }

    /**
     * @notice Add a new strategy to the protocol.
     * @param strategy The address of the strategy contract.
     */
    function addStrategy(address strategy) external onlyOwner {
        require(strategy != address(0), "Strategy address cannot be zero");
        strategies.push(IStrategy(strategy));
        cacheValid = false;
        emit StrategyAdded(strategy);
    }

    /**
     * @notice Invest available stable tokens into strategies.
     */
    function invest() external onlyOwner() {
        uint256 balance = stableToken.balanceOf(address(this));
        require(balance > 0, "No funds to invest");

        uint256 strategiesCount = strategies.length;
        require(strategiesCount > 0, "No strategies available");

        for (uint256 i = 0; i < strategiesCount; i++) {
            uint256 allocation = balance / strategiesCount;
            stableToken.approve(address(strategies[i]), allocation);

            try strategies[i].deposit(allocation) {
                // Reset approval to zero after successful usage to mitigate race conditions
                stableToken.approve(address(strategies[i]), 0);
            } catch {
                stableToken.approve(address(strategies[i]), 0); // Ensure approval is cleared
                revert("Strategy deposit failed");
            }            
        }

        cacheValid = false;        
    }

    /**
     * @notice Collect rewards from all strategies.
     */
    function collectRewards() external onlyOwner {
        uint256 totalRewards = 0;
        uint256 strategiesCount = strategies.length;

        for (uint256 i = 0; i < strategiesCount; i++) {
            uint256 strategyRewards = IStrategy(strategies[i]).getRewards();
            totalRewards += strategyRewards;

            if (strategyRewards > 0) {
                IStrategy(strategies[i]).distributedRewards(strategyRewards);
            }
        }

        require(totalRewards > 0, "No rewards to collect");
        cacheValid = false;

        emit RewardsCollected(totalRewards);
    }

    /**
     * @notice Harvest rewards from strategies.
     */
    function harvest() external onlyOwner {
        uint256 strategiesCount = strategies.length;
        for (uint256 i = 0; i < strategiesCount; i++) {
            strategies[i].harvest();
        }
        cacheValid = false;
    }

    /**
     * @notice Get the total funds in the protocol (deposits + strategies balances).
     * @return The total funds managed by the protocol.
     */
    function getTotalFunds() public view returns (uint256) {
        uint256 total = stableToken.balanceOf(address(this));
        for (uint256 i = 0; i < strategies.length; i++) {
            total += strategies[i].getBalance();
        }

        return total;
    }

    /**
     * @notice Private function to calculate total funds and update the cache.
     */
    function _getUpdateTotalFunds() private returns (uint256) {
        cachedTotalFunds = _calculateTotalFunds();
        cacheValid = true;
        return cachedTotalFunds;
    }

    /**
     * @notice Calculate the total fund without caching.
     */
    function _calculateTotalFunds() private view returns (uint256) {
        uint256 total = stableToken.balanceOf(address(this));
        uint256 strategiesCount = strategies.length;
        for (uint256 i = 0; i < strategiesCount; i++) {
            total += strategies[i].getBalance();
        }
        return total;
    }
}
