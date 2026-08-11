unit u_Types;

interface

type
  // Basic card types
  // =========================================

  TCardSuit = (csHearts, csDiamonds, csClubs, csSpades);
  TCardColor = (ccRed, ccBlack);
  TCardValue = (cvAce, cvTwo, cvThree, cvFour, cvFive, cvSix, cvSeven,
    cvEight, cvNine, cvTen, cvJack, cvQueen, cvKing);

  TCardOrdinal = 0..51;

  TCard = TCardOrdinal;

  TCardDescriptor = record
    Value: TCardValue;
    Color: TCardColor;
  end;

  // Basic table types
  // =========================================

  TTableauIndex = 1..7;

  // flat access to all stacks
  TStackId = (
    siStock,
    siWaste,
    siTableau1,siTableau2,siTableau3,siTableau4,siTableau5,siTableau6,siTableau7,
    siFoundation1,siFoundation2,siFoundation3,siFoundation4
  );
  TStackIds = set of TStackId;

  TStackCategory = (
    scStock,
    scWaste,
    scTableau,
    scFoundation);
  TStackCategories = set of TStackCategory;


  // Basic move types
  // ==========================================
  TMoveType = (
    mtDraw,
    mtRecycle,
    mtWasteToTableau,
    mtWasteToFoundation,
    mtTableauToTableau,
    mtTableauToFoundation,
    mtFoundationToTableau
  );

  TMove = record
    Source: TStackId;
    Target: TStackId;
    Count: Integer;
  end;

  TSeed = record
    Name: string;
    Value: Integer;
  end;

implementation



end.
