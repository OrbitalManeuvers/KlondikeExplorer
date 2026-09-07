---
layout: post
title: "Solver Progress"
date: 2026-09-07
---

# Woot.

![DFS solver finding a solution]({{ "/assets/images/solver-progress.png" | relative_url }})

First real end-to-end test of a DFS solver implementation. What the image shows:

In the state tree, there is a split near the top, where the solver took the bottom path, and a clever human (j/k it was me) took the upper path, and the lower path is clearly shorter. The magic of being able to try every path ...

Solvers are nasty critters if you don't plan for them from day 1. They need special move generation, special move execution, special serialization of table states ...

What the image contains:
  - a deal that was selected as solvable by running random deals through the solver. This was the 2nd shuffle it tried.
  - the solver's solution is thrown out (this was restored from a snapshot)
  - the state tree is shelved several times
  - the split point is where the solver chose a path that was simply not visible to a human:
    - top of waste required a foundation backtrack of 1 card, then the next required another ...
    - the solver used the path where a recycle would orient the cards to fall into the tableaus perfectly


One very clever piece of machinery:

```pascal

type
  TStockWastePool = record
  private
    fCards: array[0..51] of TCard;
    fCount: Integer;
    fInitialStockCount: Integer;
  public
    procedure Init(aTable: TTable);
    procedure ScanReachableMoves(aTable: TTable; aList: TList<TSolverMove>);
  end;

```

For any given state, this guy knows how to eliminate draw/recycle moves, and produce macro moves that include the stock/waste manipulation sequence require to reach each card/move. The solver doesn't need to create a state for a draw move - it just skips them and continues with moves that advance the table. Once the solver's path is found, it has to be "unrolled" in order to turn into full fidelity moves you can replay. Clever girl.

