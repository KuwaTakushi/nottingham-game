function queryBestQuoteSwapPath() private view returns (SwapSell[] memory BestQuoteSwapPath) {
    PlayerBundle memory bundle;
    bundle.swaps = new SwapSell[](MAX_SWAPS_PER_BUNDLE);
    uint256 index = 0;

    // 构建收益矩阵
    uint256[][] memory matrix = new uint256[][](ASSET_COUNT);
    for (uint8 i; i < ASSET_COUNT; ++i) {
        matrix[i] = new uint256[](ASSET_COUNT);
        for (uint8 j; j < ASSET_COUNT; ++j) {
            if (i == j) {
                matrix[i][j] = 0;
            } else {
                matrix[i][j] = GAME.quoteSell(i, j, GAME.balanceOf(PLAYER_IDX, i));
            }
        }
    }

    // 使用动态规划算法计算最佳收益路径
    uint256[][] memory dp = new uint256[][](ASSET_COUNT);
    uint8[][] memory path = new uint8[][](ASSET_COUNT);
    for (uint8 i; i < ASSET_COUNT; ++i) {
        dp[i] = new uint256[](ASSET_COUNT);
        path[i] = new uint8[](ASSET_COUNT);
        for (uint8 j; j < ASSET_COUNT; ++j) {
            dp[i][j] = matrix[i][j];
            path[i][j] = j; // 初始化路径为直接转换
        }
    }

    for (uint8 k; k < ASSET_COUNT; ++k) {
        for (uint8 i; i < ASSET_COUNT; ++i) {
            for (uint8 j; j < ASSET_COUNT; ++j) {
                if (dp[i][k] + dp[k][j] > dp[i][j]) { // 找到更优的路径
                    dp[i][j] = dp[i][k] + dp[k][j];
                    path[i][j] = k; // 更新路径
                }
            }
        }
    }

    // 找到从源资产到目标资产的最佳路径
    uint8 sourceAssetIdx = 0; // 假设源资产是 0
    uint8 targetAssetIdx = GOLD_IDX; // 假设目标资产是 GOLD_IDX
    uint256 maxProfit = dp[sourceAssetIdx][targetAssetIdx];

    // 使用 path 数组回溯，找到最佳路径上的所有资产
    uint8 currentAssetIdx = sourceAssetIdx;
    while (currentAssetIdx != targetAssetIdx) {
        uint8 nextAssetIdx = path[currentAssetIdx][targetAssetIdx];
        bundle.swaps[index++] = SwapSell({
            fromAssetIdx: currentAssetIdx,
            toAssetIdx: nextAssetIdx,
            fromAmount: GAME.balanceOf(PLAYER_IDX, currentAssetIdx)
        });
        currentAssetIdx = nextAssetIdx;
    }

    return bundle.swaps;
}


    function createBundle(uint8 /* builderIdx */) public virtual override returns (PlayerBundle memory bundle) {
        bundle.swaps = queryBestQuoteSwapPath();
    }


    function buildBlock(PlayerBundle[] calldata bundles)
        public virtual override returns (uint256 goldBid)
    {

        uint8 wantAssetIdx = _getMinGood();
        // Sell 5% of all the other goods for gold and the
        // remaining for the asset we want.
        uint256 goldBought;
        for (uint8 i; i < GOODS_COUNT; ++i) {
            uint8 assetIdx = FIRST_GOOD_IDX + i;
            if (assetIdx != GOLD_IDX) {
                goldBought += GAME.sell(
                    assetIdx,
                    GOLD_IDX,
                    GAME.balanceOf(PLAYER_IDX, assetIdx) * 3 / 100
                );
                GAME.sell(
                    assetIdx,
                    GOLD_IDX,
                    GAME.balanceOf(PLAYER_IDX, assetIdx) * 97 / 100
                );
            }
        }

        // Settle everyone else's bundles.
        for (uint8 playerIdx = 0; playerIdx < bundles.length; ++playerIdx) {
            if (playerIdx == PLAYER_IDX) {
                for (uint256 bundleIdx; bundleIdx < bundles[playerIdx-1].swaps.length; ++bundleIdx) {
                    if (bundles[playerIdx-1].swaps[bundleIdx].toAssetIdx > 0) {
                        GAME.sell(
                            bundles[playerIdx].swaps[bundleIdx].toAssetIdx,
                            GOLD_IDX,
                            GAME.balanceOf(PLAYER_IDX, bundles[playerIdx].swaps[bundleIdx].toAssetIdx)
                        );
                    }

                    if (bundles[playerIdx+1].swaps[bundleIdx].fromAssetIdx > 0) {
                        GAME.buy(
                            bundles[playerIdx].swaps[bundleIdx].fromAssetIdx,
                            GOLD_IDX,
                            GAME.balanceOf(PLAYER_IDX, bundles[playerIdx].swaps[bundleIdx].fromAssetIdx)
                        );
                    }
                }
            }

            GAME.settleBundle(playerIdx, bundles[playerIdx]);
        }
        // Bid the gold we bought.
        return goldBought;
    }



    function _getMedianGood() internal view  returns (uint8 medianAssetIdx) {
        uint256 assetCount = GOODS_COUNT;
        uint8 left = FIRST_GOOD_IDX;
        uint8 right = FIRST_GOOD_IDX + GOODS_COUNT - 1;

        while (left <= right) {
            uint8 mid = (left + right) / 2;
            uint256 midBalance = GAME.balanceOf(PLAYER_IDX, mid);
            if (assetCount % 2 == 0) {
                if (mid == left || mid == right) {
                    medianAssetIdx = mid;
                    break;
                } else {
                    uint256 nextBalance = GAME.balanceOf(PLAYER_IDX, mid + 1);
                    if (midBalance == nextBalance) {
                        medianAssetIdx = mid;
                        break;
                    } else if (midBalance < nextBalance) {
                        left = mid + 1;
                    } else {
                        right = mid - 1;
                    }
                }
            } else {
                medianAssetIdx = mid;
                break;
            }
        }

        return medianAssetIdx;
    }
