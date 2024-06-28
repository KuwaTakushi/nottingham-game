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

    function queryBestQuoteSwapPath() private view returns (SwapSell[] memory BestQuoteSwapPath) {
        uint256 index;
        for (uint8 idx; i < ASSET_COUNT; ++i) {
            if (assetIdx != GOLD_IDX) {
                uint256 balanceOf = GAME.balanceOf(PLAYER_IDX, assetIdx);
                bundle.swaps[index++] = SwapSell({
                    fromAssetIdx: idx,
                    toAssetIdx: GOLD_IDX,
                    fromAmount: balanceOf
                });
            }
        }

        uint8 bestSwapAssetIdx;
        uint256 bestSwapProfit = 0;
        for (uint8 assetIdx; assetIdx < ASSET_COUNT; ++assetIdx) {
            if (assetIdx != GOLD_IDX) {
                uint256 profit = GAME.quoteBuy(
                    GOLD_IDX,
                    assetIdx,
                    GAME.balanceOf(PLAYER_IDX, GOLD_IDX)
                );
                if (profit > bestSwapProfit) {
                    bestSwapProfit = profit;
                    bestSwapAssetIdx = assetIdx;
                }
            }
        }

        bundle.swaps[index++] = SwapSell({
            fromAssetIdx: GOLD_IDX,
            toAssetIdx: bestSwapAssetIdx,
            fromAmount: GAME.balanceOf(PLAYER_IDX, GOLD_IDX)
        });
        
        bundle.swaps[index++] = SwapSell({
            fromAssetIdx: bestSwapAssetIdx,
            toAssetIdx: GOLD_IDX,
            fromAmount: bestSwapProfit
        });

        return bundle.swaps;
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
