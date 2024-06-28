// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import './BasePlayer.sol';

// I'm Kuwatakushi エヴァンゲリオン
contract Kuwatakushi is BasePlayer {

    constructor(IGame game, uint8 playerIdx, uint8 playerCount, uint8 assetCount)
            BasePlayer(game, playerIdx, playerCount, assetCount) {}

    function createBundle(uint8 /* builderIdx */)
        public virtual override returns (PlayerBundle memory bundle)
    {
        bundle.swaps = queryBestQuoteSwapPath();
    }

    function queryBestQuoteSwapPath() private view returns (SwapSell[] memory BestQuoteSwapPath)
    {
        PlayerBundle memory bundle;
        bundle.swaps = new SwapSell[](MAX_SWAPS_PER_BUNDLE);
        uint8 maxAssetIdx = _getMaxGood();
        uint8 midAssetIdx = _getMedianGood();
        uint8 minAssetIdx = _getMinGood();

        uint256 quoteMaxAssetIdx =  GAME.quoteBuy(
                minAssetIdx /** fromAssetIdx */, 
                maxAssetIdx /** toAssetIdx */, 
                GAME.balanceOf(PLAYER_IDX, maxAssetIdx)
        );
        uint256 quoteMidAssetIdx = GAME.quoteBuy(
                minAssetIdx /** fromAssetIdx */, 
                midAssetIdx /** toAssetIdx */, 
                GAME.balanceOf(PLAYER_IDX, midAssetIdx)
        );

        uint256 possibleBestPathProfit = quoteMaxAssetIdx < quoteMidAssetIdx 
            ? 
            GAME.quoteBuy(
                minAssetIdx /** fromAssetIdx */, 
                maxAssetIdx /** toAssetIdx */, 
                GAME.balanceOf(PLAYER_IDX, maxAssetIdx)
            ) :
            GAME.quoteBuy(
                minAssetIdx /** fromAssetIdx */, 
                midAssetIdx /** toAssetIdx */, 
                GAME.balanceOf(PLAYER_IDX, midAssetIdx)
            );
        
        uint8 possibleBestPathIdx = quoteMaxAssetIdx > quoteMidAssetIdx ? maxAssetIdx : midAssetIdx;
        for (uint8 path; path <= ASSET_COUNT; ++path) {
            if (path == possibleBestPathIdx) continue;

            uint256 currentPathProfit = GAME.quoteBuy(
                minAssetIdx,
                path,
                GAME.balanceOf(PLAYER_IDX, path)
            );
            if (currentPathProfit > possibleBestPathProfit) {possibleBestPathProfit = currentPathProfit; possibleBestPathIdx = path;}
        }

        uint index;
        bundle.swaps[index++] = SwapSell({
            fromAssetIdx: possibleBestPathIdx,
            toAssetIdx: minAssetIdx,
            fromAmount: possibleBestPathProfit
        });

        bundle.swaps[index++] = SwapSell({
            fromAssetIdx: possibleBestPathIdx,
            toAssetIdx: GOLD_IDX,
            fromAmount: possibleBestPathProfit
        });
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

}

