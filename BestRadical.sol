function queryBestQuoteSwapPath() private view returns (SwapSell[] memory BestQuoteSwapPath) {
    PlayerBundle memory bundle;
    bundle.swaps = new SwapSell[](MAX_SWAPS_PER_BUNDLE);
    uint256 index = 0;

    for (uint8 assetIdx; assetIdx < ASSET_COUNT; ++assetIdx) {
        if (assetIdx != GOLD_IDX) {
            uint256 balanceOf = GAME.balanceOf(PLAYER_IDX, assetIdx);
            bundle.swaps[index++] = SwapSell({
                fromAssetIdx: assetIdx,
                toAssetIdx: GOLD_IDX,
                fromAmount: balanceOf
            });
        }
    }

    uint8 bestSwapAssetIdx = GOLD_IDX;
    uint256 bestSwapProfit = 0;
    for (uint8 assetIdx; assetIdx < ASSET_COUNT; ++assetIdx) {
        if (GAME.round() == MAX_ROUNDS) {
            if (assetIdx != GOLD_IDX) {
                uint256 profit = GAME.quoteSell(
                    assetIdx, 
                    GOLD_IDX, 
                    GAME.balanceOf(PLAYER_IDX, assetIdx) 
                );

                if (profit > bestSwapProfit) {
                    bestSwapProfit = profit;
                    bestSwapAssetIdx = assetIdx;
                }
            }
        } else {
            if (assetIdx != GOLD_IDX) {
                bundle.swaps[index++] = SwapSell({
                    fromAssetIdx: assetIdx,
                    toAssetIdx: GOLD_IDX,
                    fromAmount: GAME.balanceOf(PLAYER_IDX, assetIdx)
                });
            } 
        }
    }

    for (uint8 assetIdx; assetIdx < ASSET_COUNT; ++assetIdx) {
        if (bestSwapProfit > 0 && assetIdx != GOLD_IDX) {
            bundle.swaps[index++] = SwapSell({
                fromAssetIdx: GOLD_IDX,
                toAssetIdx: bestSwapAssetIdx,
                fromAmount: GAME.balanceOf(PLAYER_IDX, GOLD_IDX) * 80 / 100
            });
        } else {
            return bundle.swaps;
        }      
    }

    return bundle.swaps;
}
