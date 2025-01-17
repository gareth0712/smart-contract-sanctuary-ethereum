// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
import "./BToken.sol";
import "./ErrorReporter.sol";
import "./Price.sol";
import "./ComptrollerInterface.sol";
import "./ComptrollerStorage.sol";
import "./Unitroller.sol";
import "./Bardi.sol";
contract Comptroller is ComptrollerV7Storage, ComptrollerInterface, ComptrollerErrorReporter, ExponentialNoError {
    /// @notice Emitted when an admin supports a market
    event MarketListed(BToken bToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(BToken bToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(BToken bToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(BToken bToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(Price oldPrice, Price newPrice);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(BToken bToken, string action, bool pauseState);

    /// @notice Emitted when a new borrow-side COMP speed is calculated for a market
    event CompBorrowSpeedUpdated(BToken indexed bToken, uint newSpeed);

    /// @notice Emitted when a new supply-side COMP speed is calculated for a market
    event CompSupplySpeedUpdated(BToken indexed bToken, uint newSpeed);

    /// @notice Emitted when a new COMP speed is set for a contributor
    event ContributorCompSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when COMP is distributed to a supplier
    event DistributedSupplierComp(BToken indexed bToken, address indexed supplier, uint compDelta, uint compSupplyIndex);

    /// @notice Emitted when COMP is distributed to a borrower
    event DistributedBorrowerComp(BToken indexed bToken, address indexed borrower, uint compDelta, uint compBorrowIndex);

    /// @notice Emitted when borrow cap for a bToken is changed
    event NewBorrowCap(BToken indexed bToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    /// @notice Emitted when COMP is granted by admin
    event CompGranted(address recipient, uint amount);

    /// @notice Emitted when COMP accrued for a user has been manually adjusted.
    event CompAccruedAdjusted(address indexed user, uint oldCompAccrued, uint newCompAccrued);

    /// @notice Emitted when COMP receivable for a user has been updated.
    event CompReceivableUpdated(address indexed user, uint oldCompReceivable, uint newCompReceivable);

    /// @notice The initial COMP index for a market
    uint224 public constant compInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    constructor() public {
        admin = msg.sender;
    }

    // Assets You Are In
    function getAssetsIn(address account) external view returns (BToken[] memory) {
        BToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }
    function checkMembership(address account, BToken bToken) external view returns (bool) {
        return markets[address(bToken)].accountMembership[account];
    }
    function enterMarkets(address[] memory bTokens) public returns (uint[] memory) {
        uint len = bTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            BToken bToken = BToken(bTokens[i]);

            results[i] = uint(addToMarketInternal(bToken, msg.sender));
        }

        return results;
    }
    function addToMarketInternal(BToken bToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(bToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(bToken);

        emit MarketEntered(bToken, borrower);

        return Error.NO_ERROR;
    }
    function exitMarket(address bTokenAddress) external returns (uint) {
        BToken bToken = BToken(bTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the bToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = bToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(bTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(bToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set bToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete bToken from the account’s list of assets */
        // load into memory for faster iteration
        BToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == bToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        BToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(bToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    // Policy Hooks
    function mintAllowed(address bToken, address minter, uint mintAmount) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[bToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[bToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(bToken);
        distributeSupplierComp(bToken, minter);

        return uint(Error.NO_ERROR);
    }


    function mintVerify(address bToken, address minter, uint actualMintAmount, uint mintTokens) external {
        // Shh - currently unused
        bToken;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function redeemAllowed(address bToken, address redeemer, uint redeemTokens) external returns (uint) {
        uint allowed = redeemAllowedInternal(bToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(bToken);
        distributeSupplierComp(bToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address bToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[bToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[bToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, BToken(bToken), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }
    function redeemVerify(address bToken, address redeemer, uint redeemAmount, uint redeemTokens) external {
        // Shh - currently unused
        bToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }
    function borrowAllowed(address bToken, address borrower, uint borrowAmount) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[bToken], "borrow is paused");

        if (!markets[bToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!markets[bToken].accountMembership[borrower]) {
            // only bTokens may call borrowAllowed if borrower not in market
            require(msg.sender == bToken, "sender must be bToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(BToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[bToken].accountMembership[borrower]);
        }

        if (price.getUnderlyingPrice(BToken(bToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }


        uint borrowCap = borrowCaps[bToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = BToken(bToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, BToken(bToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: BToken(bToken).borrowIndex()});
        updateCompBorrowIndex(bToken, borrowIndex);
        distributeBorrowerComp(bToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }
    function borrowVerify(address bToken, address borrower, uint borrowAmount) external {
        // Shh - currently unused
        bToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function repayBorrowAllowed(
        address bToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[bToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: BToken(bToken).borrowIndex()});
        updateCompBorrowIndex(bToken, borrowIndex);
        distributeBorrowerComp(bToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }
    function repayBorrowVerify(
        address bToken,
        address payer,
        address borrower,
        uint actualRepayAmount,
        uint borrowerIndex) external {
        // Shh - currently unused
        bToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function liquidateBorrowAllowed(
        address bTokenBorrowed,
        address bTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint) {
        // Shh - currently unused
        liquidator;

        if (!markets[bTokenBorrowed].isListed || !markets[bTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        uint borrowBalance = BToken(bTokenBorrowed).borrowBalanceStored(borrower);

        /* allow accounts to be liquidated if the market is deprecated */
        if (isDeprecated(BToken(bTokenBorrowed))) {
            require(borrowBalance >= repayAmount, "Can not repay more than the total borrow");
        } else {
            /* The borrower must have shortfall in order to be liquidatable */
            (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            if (shortfall == 0) {
                return uint(Error.INSUFFICIENT_SHORTFALL);
            }

            /* The liquidator may not repay more than what is allowed by the closeFactor */
            uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
            if (repayAmount > maxClose) {
                return uint(Error.TOO_MUCH_REPAY);
            }
        }
        return uint(Error.NO_ERROR);
    }
    function liquidateBorrowVerify(
        address bTokenBorrowed,
        address bTokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) external {
        // Shh - currently unused
        bTokenBorrowed;
        bTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function seizeAllowed(
        address bTokenCollateral,
        address bTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[bTokenCollateral].isListed || !markets[bTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (BToken(bTokenCollateral).comptroller() != BToken(bTokenBorrowed).comptroller()) {
            return uint(Error.COMPTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(bTokenCollateral);
        distributeSupplierComp(bTokenCollateral, borrower);
        distributeSupplierComp(bTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }
    function seizeVerify(
        address bTokenCollateral,
        address bTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external {
        // Shh - currently unused
        bTokenCollateral;
        bTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }
    function transferAllowed(address bToken, address src, address dst, uint transferTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(bToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(bToken);
        distributeSupplierComp(bToken, src);
        distributeSupplierComp(bToken, dst);

        return uint(Error.NO_ERROR);
    }
    function transferVerify(address bToken, address src, address dst, uint transferTokens) external {
        // Shh - currently unused
        bToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    // Liquidity/Liquidation Calculations
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint bTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint PriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, BToken(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, BToken(0), 0, 0);
    }
    function getHypotheticalAccountLiquidity(
        address account,
        address bTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, BToken(bTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }
    function getHypotheticalAccountLiquidityInternal(
        address account,
        BToken bTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        BToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            BToken asset = assets[i];

            // Read the balances and exchange rate from the bToken
            (oErr, vars.bTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.PriceMantissa = price.getUnderlyingPrice(asset);
            if (vars.PriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.PriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * bTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.bTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with bTokenModify
            if (asset == bTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }
    function liquidateCalculateSeizeTokens(address bTokenBorrowed, address bTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = price.getUnderlyingPrice(BToken(bTokenBorrowed));
        uint priceCollateralMantissa = price.getUnderlyingPrice(BToken(bTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }
        uint exchangeRateMantissa = BToken(bTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    // Admin Functions 
    function _setPriceOracle(Price newPrice) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the comptroller
        Price oldOracle = price;

        // Set comptroller's oracle to newPrice
        price = newPrice;

        // Emit NewPriceOracle(oldOracle, newPrice)
        emit NewPriceOracle(oldOracle, newPrice);

        return uint(Error.NO_ERROR);
    }
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
    	require(msg.sender == admin, "only admin can set close factor");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }
    function _setCollateralFactor(BToken bToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(bToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && price.getUnderlyingPrice(bToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(bToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }
    function _supportMarket(BToken bToken) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[address(bToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        bToken.isBToken(); // Sanity check to make sure its really a bToken

        // Note that isComped is not in active use anymore
        markets[address(bToken)] = Market({isListed: true, isComped: false, collateralFactorMantissa: 0});

        _addMarketInternal(address(bToken));
        _initializeMarket(address(bToken));

        emit MarketListed(bToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address bToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != BToken(bToken), "market already added");
        }
        allMarkets.push(BToken(bToken));
    }

    function _initializeMarket(address bToken) internal {
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");

        CompMarketState storage supplyState = compSupplyState[bToken];
        CompMarketState storage borrowState = compBorrowState[bToken];

        /*
         * Update market state indices
         */
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = compInitialIndex;
        }

        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = compInitialIndex;
        }

        /*
         * Update market state block numbers
         */
         supplyState.block = borrowState.block = blockNumber;
    }
    function _setMarketBorrowCaps(BToken[] calldata bTokens, uint[] calldata newBorrowCaps) external {
    	require(msg.sender == admin || msg.sender == borrowCapGuardian, "only admin or borrow cap guardian can set borrow caps"); 

        uint numMarkets = bTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(bTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(bTokens[i], newBorrowCaps[i]);
        }
    }
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == admin, "only admin can set borrow cap guardian");

        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;

        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;

        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _setMintPaused(BToken bToken, bool state) public returns (bool) {
        require(markets[address(bToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        mintGuardianPaused[address(bToken)] = state;
        emit ActionPaused(bToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(BToken bToken, bool state) public returns (bool) {
        require(markets[address(bToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        borrowGuardianPaused[address(bToken)] = state;
        emit ActionPaused(bToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        require(unitroller._acceptImplementation() == 0, "change not authorized");
    }

    /// @notice Delete this function after proposal 65 is executed
    function fixBadAccruals(address[] calldata affectedUsers, uint[] calldata amounts) external {
        require(msg.sender == admin, "Only admin can call this function"); // Only the timelock can call this function
        require(!proposal65FixExecuted, "Already executed this one-off function"); // Require that this function is only called once
        require(affectedUsers.length == amounts.length, "Invalid input");

        // Loop variables
        address user;
        uint currentAccrual;
        uint amountToSubtract;
        uint newAccrual;

        // Iterate through all affected users
        for (uint i = 0; i < affectedUsers.length; ++i) {
            user = affectedUsers[i];
            currentAccrual = compAccrued[user];

            amountToSubtract = amounts[i];

            // The case where the user has claimed and received an incorrect amount of COMP.
            // The user has less currently accrued than the amount they incorrectly received.
            if (amountToSubtract > currentAccrual) {
                // Amount of COMP the user owes the protocol
                uint accountReceivable = amountToSubtract - currentAccrual; // Underflow safe since amountToSubtract > currentAccrual

                uint oldReceivable = compReceivable[user];
                uint newReceivable = add_(oldReceivable, accountReceivable);

                // Accounting: record the COMP debt for the user
                compReceivable[user] = newReceivable;

                emit CompReceivableUpdated(user, oldReceivable, newReceivable);

                amountToSubtract = currentAccrual;
            }
            
            if (amountToSubtract > 0) {
                // Subtract the bad accrual amount from what they have accrued.
                // Users will keep whatever they have correctly accrued.
                compAccrued[user] = newAccrual = sub_(currentAccrual, amountToSubtract);

                emit CompAccruedAdjusted(user, currentAccrual, newAccrual);
            }
        }

        proposal65FixExecuted = true; // Makes it so that this function cannot be called again
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }

    // Comp Distribution 
    function setCompSpeedInternal(BToken bToken, uint supplySpeed, uint borrowSpeed) internal {
        Market storage market = markets[address(bToken)];
        require(market.isListed, "comp market is not listed");

        if (compSupplySpeeds[address(bToken)] != supplySpeed) {
            // Supply speed updated so let's update supply state to ensure that
            //  1. COMP accrued properly for the old speed, and
            //  2. COMP accrued at the new speed starts after this block.
            updateCompSupplyIndex(address(bToken));

            // Update speed and emit event
            compSupplySpeeds[address(bToken)] = supplySpeed;
            emit CompSupplySpeedUpdated(bToken, supplySpeed);
        }

        if (compBorrowSpeeds[address(bToken)] != borrowSpeed) {
            // Borrow speed updated so let's update borrow state to ensure that
            //  1. COMP accrued properly for the old speed, and
            //  2. COMP accrued at the new speed starts after this block.
            Exp memory borrowIndex = Exp({mantissa: bToken.borrowIndex()});
            updateCompBorrowIndex(address(bToken), borrowIndex);

            // Update speed and emit event
            compBorrowSpeeds[address(bToken)] = borrowSpeed;
            emit CompBorrowSpeedUpdated(bToken, borrowSpeed);
        }
    }

    /**
     * @notice Accrue COMP to the market by updating the supply index
     * @param bToken The market whose supply index to update
     * @dev Index is a cumulative sum of the COMP per bToken accrued.
     */
    function updateCompSupplyIndex(address bToken) internal {
        CompMarketState storage supplyState = compSupplyState[bToken];
        uint supplySpeed = compSupplySpeeds[bToken];
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        uint deltaBlocks = sub_(uint(blockNumber), uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = BToken(bToken).totalSupply();
            uint compAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(compAccrued, supplyTokens) : Double({mantissa: 0});
            supplyState.index = safe224(add_(Double({mantissa: supplyState.index}), ratio).mantissa, "new index exceeds 224 bits");
            supplyState.block = blockNumber;
        } else if (deltaBlocks > 0) {
            supplyState.block = blockNumber;
        }
    }
    function updateCompBorrowIndex(address bToken, Exp memory marketBorrowIndex) internal {
        CompMarketState storage borrowState = compBorrowState[bToken];
        uint borrowSpeed = compBorrowSpeeds[bToken];
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        uint deltaBlocks = sub_(uint(blockNumber), uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(BToken(bToken).totalBorrows(), marketBorrowIndex);
            uint compAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(compAccrued, borrowAmount) : Double({mantissa: 0});
            borrowState.index = safe224(add_(Double({mantissa: borrowState.index}), ratio).mantissa, "new index exceeds 224 bits");
            borrowState.block = blockNumber;
        } else if (deltaBlocks > 0) {
            borrowState.block = blockNumber;
        }
    }
    function distributeSupplierComp(address bToken, address supplier) internal {
        // TODO: Don't distribute supplier COMP if the user is not in the supplier market.
        // This check should be as gas efficient as possible as distributeSupplierComp is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        CompMarketState storage supplyState = compSupplyState[bToken];
        uint supplyIndex = supplyState.index;
        uint supplierIndex = compSupplierIndex[bToken][supplier];

        // Update supplier's index to the current index since we are distributing accrued COMP
        compSupplierIndex[bToken][supplier] = supplyIndex;

        if (supplierIndex == 0 && supplyIndex >= compInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with COMP accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = compInitialIndex;
        }

        // Calculate change in the cumulative sum of the COMP per bToken accrued
        Double memory deltaIndex = Double({mantissa: sub_(supplyIndex, supplierIndex)});

        uint supplierTokens = BToken(bToken).balanceOf(supplier);

        // Calculate COMP accrued: bTokenAmount * accruedPerBToken
        uint supplierDelta = mul_(supplierTokens, deltaIndex);

        uint supplierAccrued = add_(compAccrued[supplier], supplierDelta);
        compAccrued[supplier] = supplierAccrued;

        emit DistributedSupplierComp(BToken(bToken), supplier, supplierDelta, supplyIndex);
    }
    function distributeBorrowerComp(address bToken, address borrower, Exp memory marketBorrowIndex) internal {
        // TODO: Don't distribute supplier COMP if the user is not in the borrower market.
        // This check should be as gas efficient as possible as distributeBorrowerComp is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        CompMarketState storage borrowState = compBorrowState[bToken];
        uint borrowIndex = borrowState.index;
        uint borrowerIndex = compBorrowerIndex[bToken][borrower];

        // Update borrowers's index to the current index since we are distributing accrued COMP
        compBorrowerIndex[bToken][borrower] = borrowIndex;

        if (borrowerIndex == 0 && borrowIndex >= compInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with COMP accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = compInitialIndex;
        }

        // Calculate change in the cumulative sum of the COMP per borrowed unit accrued
        Double memory deltaIndex = Double({mantissa: sub_(borrowIndex, borrowerIndex)});

        uint borrowerAmount = div_(BToken(bToken).borrowBalanceStored(borrower), marketBorrowIndex);
        
        // Calculate COMP accrued: bTokenAmount * accruedPerBorrowedUnit
        uint borrowerDelta = mul_(borrowerAmount, deltaIndex);

        uint borrowerAccrued = add_(compAccrued[borrower], borrowerDelta);
        compAccrued[borrower] = borrowerAccrued;

        emit DistributedBorrowerComp(BToken(bToken), borrower, borrowerDelta, borrowIndex);
    }
    function updateContributorRewards(address contributor) public {
        uint compSpeed = compContributorSpeeds[contributor];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && compSpeed > 0) {
            uint newAccrued = mul_(deltaBlocks, compSpeed);
            uint contributorAccrued = add_(compAccrued[contributor], newAccrued);

            compAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;
        }
    }
    function claimComp(address holder) public {
        return claimComp(holder, allMarkets);
    }
    function claimComp(address holder, BToken[] memory bTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimComp(holders, bTokens, true, true);
    }
    function claimComp(address[] memory holders, BToken[] memory bTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < bTokens.length; i++) {
            BToken bToken = bTokens[i];
            require(markets[address(bToken)].isListed, "market must be listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: bToken.borrowIndex()});
                updateCompBorrowIndex(address(bToken), borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerComp(address(bToken), holders[j], borrowIndex);
                }
            }
            if (suppliers == true) {
                updateCompSupplyIndex(address(bToken));
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierComp(address(bToken), holders[j]);
                }
            }
        }
        for (uint j = 0; j < holders.length; j++) {
            compAccrued[holders[j]] = grantCompInternal(holders[j], compAccrued[holders[j]]);
        }
    }
    function grantCompInternal(address user, uint amount) internal returns (uint) {
        Bardi bardi = Bardi(getCompAddress());
        uint compRemaining = bardi.balanceOf(address(this));
        if (amount > 0 && amount <= compRemaining) {
            bardi.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    // Comp Distribution Admin 
    function _grantComp(address recipient, uint amount) public {
        require(adminOrInitializing(), "only admin can grant comp");
        uint amountLeft = grantCompInternal(recipient, amount);
        require(amountLeft == 0, "insufficient comp for grant");
        emit CompGranted(recipient, amount);
    }
    function _setCompSpeeds(BToken[] memory bTokens, uint[] memory supplySpeeds, uint[] memory borrowSpeeds) public {
        require(adminOrInitializing(), "only admin can set comp speed");

        uint numTokens = bTokens.length;
        require(numTokens == supplySpeeds.length && numTokens == borrowSpeeds.length, "Comptroller::_setCompSpeeds invalid input");

        for (uint i = 0; i < numTokens; ++i) {
            setCompSpeedInternal(bTokens[i], supplySpeeds[i], borrowSpeeds[i]);
        }
    }
    function _setContributorCompSpeed(address contributor, uint compSpeed) public {
        require(adminOrInitializing(), "only admin can set comp speed");

        // note that COMP speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (compSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        compContributorSpeeds[contributor] = compSpeed;

        emit ContributorCompSpeedUpdated(contributor, compSpeed);
    }
    function getAllMarkets() public view returns (BToken[] memory) {
        return allMarkets;
    }
    function isDeprecated(BToken bToken) public view returns (bool) {
        return
            markets[address(bToken)].collateralFactorMantissa == 0 && 
            borrowGuardianPaused[address(bToken)] == true && 
            bToken.reserveFactorMantissa() == 1e18
        ;
    }
    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
    function getCompAddress() public pure returns (address) {
        return 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    }
}