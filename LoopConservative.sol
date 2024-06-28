function queryBestQuoteSwapPath() private view returns (SwapSell[] memory BestQuoteSwapPath) {
    PlayerBundle memory bundle;
    bundle.swaps = new SwapSell[](MAX_SWAPS_PER_BUNDLE);

    uint256 previousProfit = 0; 
    uint256 currentProfit;
    uint8 currentAssetIdx = GOLD_IDX; 
    uint8 index = 0;

    while (currentProfit > previousProfit) {
        previousProfit = currentProfit;

        uint8 maxAssetIdx = _getMaxGood();
        uint8 midAssetIdx = _getMedianGood();
        uint8 minAssetIdx = _getMinGood();

        uint256 quoteMaxAssetIdx =  GAME.quoteBuy(
            currentAssetIdx, 
            maxAssetIdx, 
            GAME.balanceOf(PLAYER_IDX, maxAssetIdx)
        );
        uint256 quoteMidAssetIdx = GAME.quoteBuy(
            currentAssetIdx, 
            midAssetIdx, 
            GAME.balanceOf(PLAYER_IDX, midAssetIdx)
        );

        uint256 possibleBestPathProfit = quoteMaxAssetIdx < quoteMidAssetIdx 
            ? 
            GAME.quoteBuy(
                currentAssetIdx, 
                maxAssetIdx, 
                GAME.balanceOf(PLAYER_IDX, maxAssetIdx)
            ) :
            GAME.quoteBuy(
                currentAssetIdx, 
                midAssetIdx, 
                GAME.balanceOf(PLAYER_IDX, midAssetIdx)
            );
        
        uint8 possibleBestPathIdx = quoteMaxAssetIdx > quoteMidAssetIdx ? maxAssetIdx : midAssetIdx;
        for (uint8 path; path <= ASSET_COUNT; ++path) {
            if (path == possibleBestPathIdx) continue;

            uint256 currentPathProfit = GAME.quoteBuy(
                currentAssetIdx,
                path,
                GAME.balanceOf(PLAYER_IDX, path)
            );
            if (currentPathProfit > possibleBestPathProfit) {
                possibleBestPathProfit = currentPathProfit;
                possibleBestPathIdx = path;
            }
        }

        currentAssetIdx = possibleBestPathIdx;
        currentProfit = possibleBestPathProfit;

        bundle.swaps[index++] = SwapSell({
            fromAssetIdx: currentAssetIdx, 
            toAssetIdx: GOLD_IDX,
            fromAmount: currentProfit
        });
    }

    return bundle.swaps;
}
