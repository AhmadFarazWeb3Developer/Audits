// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IERC20WithDecimals {
    function decimals() external view returns (uint8);
}

import {IUniswapV1Exchange} from "../Interface/IUniswapV1Exchange.sol";

contract UniswapV1Exchange is IUniswapV1Exchange {
    address public factory;
    address public override tokenAddress;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    function setup(address token_addr) external override {
        require(factory == address(0), "Exchange: already initialized");
        require(token_addr != address(0), "Exchange: invalid token");
        factory = msg.sender;
        tokenAddress = token_addr;
    }

    function factoryAddress() external view override returns (address out) {
        return factory;
    }

    function decimals() external view override returns (uint256 out) {
        return IERC20WithDecimals(tokenAddress).decimals();
    }

    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable override returns (uint256 out) {
        require(deadline >= block.timestamp, "Exchange: deadline passed");
        require(max_tokens > 0 && msg.value > 0, "Exchange: invalid input");
        IERC20 token = IERC20(tokenAddress);
        uint256 eth_amount = msg.value;
        uint256 token_amount = eth_amount; // 1:1 ratio
        require(
            token_amount <= max_tokens,
            "Exchange: token amount exceeds max"
        );
        require(
            token.transferFrom(msg.sender, address(this), token_amount),
            "Exchange: token transfer failed"
        );

        uint256 liquidity;
        if (totalSupply == 0) {
            liquidity = eth_amount; // Initial liquidity sets 1:1 ratio
        } else {
            uint256 eth_reserve = address(this).balance - msg.value;
            uint256 token_reserve = token.balanceOf(address(this)) -
                token_amount;
            liquidity = (eth_amount * totalSupply) / eth_reserve;
            require(
                liquidity >= min_liquidity,
                "Exchange: insufficient liquidity"
            );
        }

        balanceOf[msg.sender] += liquidity;
        totalSupply += liquidity;
        emit AddLiquidity(msg.sender, eth_amount, token_amount);
        emit Transfer(address(0), msg.sender, liquidity);
        return liquidity;
    }

    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external override returns (uint256, uint256) {
        require(deadline >= block.timestamp, "Exchange: deadline passed");
        require(
            amount > 0 && balanceOf[msg.sender] >= amount,
            "Exchange: insufficient liquidity"
        );
        IERC20 token = IERC20(tokenAddress);
        uint256 eth_reserve = address(this).balance;
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_amount = (amount * eth_reserve) / totalSupply;
        uint256 token_amount = (amount * token_reserve) / totalSupply;
        require(eth_amount >= min_eth, "Exchange: insufficient ETH output");
        require(
            token_amount >= min_tokens,
            "Exchange: insufficient token output"
        );

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        payable(msg.sender).transfer(eth_amount);
        require(
            token.transfer(msg.sender, token_amount),
            "Exchange: token transfer failed"
        );
        emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
        emit Transfer(msg.sender, address(0), amount);
        return (eth_amount, token_amount);
    }

    function ethToTokenSwapInput(
        uint256 min_tokens,
        uint256 deadline
    ) external payable override returns (uint256 out) {
        require(deadline >= block.timestamp, "Exchange: deadline passed");
        require(msg.value > 0, "Exchange: no ETH provided");
        uint256 tokens_bought = msg.value; // 1:1 ratio
        require(
            tokens_bought >= min_tokens,
            "Exchange: insufficient token output"
        );
        require(
            IERC20(tokenAddress).transfer(msg.sender, tokens_bought),
            "Exchange: token transfer failed"
        );
        emit TokenPurchase(msg.sender, msg.value, tokens_bought);
        return tokens_bought;
    }

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external override returns (uint256 out) {
        require(deadline >= block.timestamp, "Exchange: deadline passed");
        require(tokens_sold > 0, "Exchange: no tokens provided");
        uint256 eth_bought = tokens_sold; // 1:1 ratio
        require(eth_bought >= min_eth, "Exchange: insufficient ETH output");
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokens_sold
            ),
            "Exchange: token transfer failed"
        );
        payable(msg.sender).transfer(eth_bought);
        emit EthPurchase(msg.sender, tokens_sold, eth_bought);
        return eth_bought;
    }

    function getEthToTokenInputPrice(
        uint256 eth_sold
    ) external view override returns (uint256 out) {
        return eth_sold; // 1:1 ratio
    }

    function getTokenToEthInputPrice(
        uint256 tokens_sold
    ) external view override returns (uint256 out) {
        return tokens_sold; // 1:1 ratio
    }

    function transfer(
        address _to,
        uint256 _value
    ) external override returns (bool out) {
        require(_to != address(0), "Exchange: invalid recipient");
        require(
            balanceOf[msg.sender] >= _value,
            "Exchange: insufficient balance"
        );
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) external override returns (bool out) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool out) {
        require(_to != address(0), "Exchange: invalid recipient");
        require(balanceOf[_from] >= _value, "Exchange: insufficient balance");
        require(
            _allowance[_from][msg.sender] >= _value,
            "Exchange: insufficient allowance"
        );
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override returns (uint256 out) {
        return _allowance[_owner][_spender];
    }

    function name() external view override returns (bytes32 out) {
        return bytes32("Uniswap V1 Exchange");
    }

    function symbol() external view override returns (bytes32 out) {
        return bytes32("UNI-V1");
    }

    receive() external payable {}

    // Unimplemented functions
    function ethToTokenSwapOutput(
        uint256,
        uint256
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function ethToTokenTransferInput(
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function ethToTokenTransferOutput(
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function getEthToTokenOutputPrice(
        uint256
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function getTokenToEthOutputPrice(
        uint256
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToEthSwapOutput(
        uint256,
        uint256,
        uint256
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToEthTransferInput(
        uint256,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToEthTransferOutput(
        uint256,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToExchangeSwapInput(
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToExchangeSwapOutput(
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToExchangeTransferInput(
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToExchangeTransferOutput(
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToTokenSwapInput(
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToTokenSwapOutput(
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToTokenTransferInput(
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
    function tokenToTokenTransferOutput(
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address
    ) external pure override returns (uint256) {
        revert("Not implemented");
    }
}
