codeunit 50055 "SLGI CSH Update Analysis View"
{
    Permissions = tabledata "SLGI Cash G/L Entry" = r,
                  tabledata "G/L Budget Entry" = r,
                  tabledata "Analysis View" = rm,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Analysis View Entry" = rimd,
                  tabledata "Analysis View Budget Entry" = rimd;
    TableNo = "Analysis View";

    trigger OnRun()
    begin
        if Rec.Code <> '' then begin
            InitLastEntryNo();
            Rec.LockTable();
            Rec.Find();
            AnalysisViewEntry.SetRange("Analysis View Code", Rec.Code);
            AnalysisViewEntry.DeleteAll;
            Rec."Last Entry No." := 0;
            UpdateOne(Rec, 2, true);
        end;
    end;

    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        CashGLEntry: Record "SLGI Cash G/L Entry";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewFilter: Record "Analysis View Filter";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        TempAnalysisViewEntry: Record "Analysis View Entry" temporary;
        TempAnalysisViewBudgetEntry: Record "Analysis View Budget Entry" temporary;
        TempDimBuf: Record "Dimension Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimEntryBuffer: Record "Dimension Entry Buffer" temporary;
        Window: Dialog;
        FilterIsInitialized: Boolean;
        FiltersExist: Boolean;
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
        NoOfEntries: Integer;
        ShowProgressWindow: Boolean;
        WinLastEntryNo: Integer;
        WinUpdateCounter: Integer;
        WinTotalCounter: Integer;
        WinTime0: Time;
        WinTime1: Time;
        WinTime2: Time;
        LastGLEntryNo: Integer;
        LastBudgetEntryNo: Integer;
        LastEntryNoIsInitialized: Boolean;

        Text005: Label 'Analysis View     #1############################\\';
        Text006: Label 'Updating table    #2############################\';
        Text007: Label 'Speed: (Entries/s)#4########\';
        Text008: Label 'Average Speed     #5########';
        Text009: Label '#6############### @3@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\';
        Text010: Label 'Summarizing';
        Text011: Label 'Updating Database';

    local procedure InitLastEntryNo()
    begin
        CashGLEntry.Reset();
        GLBudgetEntry.Reset();
        if LastEntryNoIsInitialized then
            exit;
        LastGLEntryNo := CashGLEntry.GetLastEntryNo();
        LastBudgetEntryNo := GLBudgetEntry.GetLastEntryNo();
        LastEntryNoIsInitialized := true;
    end;

    procedure UpdateAll(Which: Option "Ledger Entries","Budget Entries",Both; DirectlyFromPosting: Boolean)
    var
        AnalysisView2: Record "Analysis View";
    begin

        AnalysisView2.SetRange(Blocked, false);
        if DirectlyFromPosting then
            AnalysisView2.SetRange("Update on Posting", true);

        if AnalysisView2.IsEmpty() then
            exit;

        InitLastEntryNo();

        if DirectlyFromPosting then
            AnalysisView2.SetFilter("Last Entry No.", '<%1', LastGLEntryNo);

        AnalysisView2.LockTable();
        if AnalysisView2.FindSet() then
            repeat
                UpdateOne(AnalysisView2, Which, not DirectlyFromPosting and (AnalysisView2."Last Entry No." < LastGLEntryNo - 1000));
            until AnalysisView2.Next() = 0;

    end;

    procedure Update(var NewAnalysisView: Record "Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; ShowWindow: Boolean)
    begin
        InitLastEntryNo();
        NewAnalysisView.LockTable();
        NewAnalysisView.Find();
        UpdateOne(NewAnalysisView, Which, ShowWindow);
    end;

    procedure UpdateOne(var NewAnalysisView: Record "Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; ShowWindow: Boolean)
    var
        Updated: Boolean;
        IsHandled: Boolean;
    begin
        AnalysisView := NewAnalysisView;
        AnalysisView.TestField(Blocked, false);
        ShowProgressWindow := ShowWindow and GuiAllowed;
        if ShowProgressWindow then
            InitWindow();

        if AnalysisView."Account Source" = AnalysisView."Account Source"::"G/L Account" then begin
            if Which in [Which::"Ledger Entries", Which::Both] then
                if LastGLEntryNo > AnalysisView."Last Entry No." then begin
                    if ShowProgressWindow then
                        UpdateWindowHeader(Database::"Analysis View Entry", CashGLEntry."Entry No.");
                    UpdateEntries();
                    AnalysisView."Last Entry No." := LastGLEntryNo;
                    Updated := true;
                end;
        end else
            Error('Cash Basis does not support Cash Flow Accounts');

        if (Which in [Which::"Budget Entries", Which::Both]) and
           NewAnalysisView."Include Budgets"
        then
            if LastBudgetEntryNo > AnalysisView."Last Budget Entry No." then begin
                if ShowProgressWindow then
                    UpdateWindowHeader(Database::"Analysis View Budget Entry", GLBudgetEntry."Entry No.");
                GLBudgetEntry.Reset();
                GLBudgetEntry.SetRange("Entry No.", AnalysisView."Last Budget Entry No." + 1, LastBudgetEntryNo);
                UpdateBudgetEntries(AnalysisView."Last Budget Entry No." + 1);
                AnalysisView."Last Budget Entry No." := LastBudgetEntryNo;
                Updated := true;
            end;

        if Updated then begin
            AnalysisView."Last Date Updated" := Today;
            AnalysisView."Reset Needed" := false;
            AnalysisView.Modify();
        end;

        if ShowProgressWindow then
            Window.Close();
    end;

    local procedure UpdateEntries()
    begin
        GLSetup.Get();
        FilterIsInitialized := false;
        if AnalysisView."Account Source" = AnalysisView."Account Source"::"G/L Account" then
            UpdateEntriesForGLAccount()
        else
            Error('Cash Basis does not support Cash Flow Accounts');

        FlushAnalysisViewEntry();
    end;

    local procedure UpdateEntriesForGLAccount()
    var
        AnalysisViewGLQry: Query "SLGI CSH Analysis View Source";
        EntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        if IsHandled then
            exit;

        if AnalysisView."Date Compression" = AnalysisView."Date Compression"::None then begin
            UpdateEntriesForGLAccountDetailed();
            exit;
        end;

        AnalysisViewGLQry.SetRange(AnalysisViewCode, AnalysisView.Code);
        AnalysisViewGLQry.SetRange(EntryNo, AnalysisView."Last Entry No." + 1, LastGLEntryNo);
        if AnalysisView."Account Filter" = '' then
            AnalysisViewGLQry.SetFilter(GLAccNo, '>%1', '')
        else
            AnalysisViewGLQry.SetFilter(GLAccNo, AnalysisView."Account Filter");

        AnalysisViewGLQry.Open();
        while AnalysisViewGLQry.Read() do begin
            if DimSetIDInFilter(AnalysisViewGLQry.DimensionSetID, AnalysisView) then
                UpdateAnalysisViewEntry(
                  AnalysisViewGLQry.GLAccNo,
                  '',
                  AnalysisViewGLQry.DimVal1,
                  AnalysisViewGLQry.DimVal2,
                  AnalysisViewGLQry.DimVal3,
                  AnalysisViewGLQry.DimVal4,
                  AnalysisViewGLQry.PostingDate,
                  AnalysisViewGLQry.Amount,
                  AnalysisViewGLQry.DebitAmount,
                  AnalysisViewGLQry.CreditAmount,
                  0);
            EntryNo := EntryNo + 1;
            if ShowProgressWindow then
                UpdateWindowCounter(EntryNo);
        end;
        AnalysisViewGLQry.Close();
    end;

    local procedure UpdateEntriesForGLAccountDetailed()
    var
        CashBasisEntry: Record "SLGI Cash G/L Entry";
        EntryNo: Integer;
    begin
        CashBasisEntry.SetRange("Entry No.", AnalysisView."Last Entry No." + 1, LastGLEntryNo);
        if AnalysisView."Account Filter" <> '' then
            CashBasisEntry.SetFilter("G/L Account No.", AnalysisView."Account Filter");

        if CashBasisEntry.FindSet() then
            repeat
                if DimSetIDInFilter(CashBasisEntry."Dimension Set ID", AnalysisView) then
                    UpdateAnalysisViewEntry(
                      CashBasisEntry."G/L Account No.", '',
                      GetDimVal(AnalysisView."Dimension 1 Code", CashBasisEntry."Dimension Set ID"),
                      GetDimVal(AnalysisView."Dimension 2 Code", CashBasisEntry."Dimension Set ID"),
                      GetDimVal(AnalysisView."Dimension 3 Code", CashBasisEntry."Dimension Set ID"),
                      GetDimVal(AnalysisView."Dimension 4 Code", CashBasisEntry."Dimension Set ID"),
                      CashBasisEntry."Posting Date", CashBasisEntry.Amount, CashBasisEntry."Debit Amount", CashBasisEntry."Credit Amount",
                      CashBasisEntry."Entry No.");
                EntryNo := EntryNo + 1;
                if ShowProgressWindow then
                    UpdateWindowCounter(EntryNo);
            until CashBasisEntry.Next() = 0;
    end;

    local procedure UpdateBudgetEntries(DeleteFromEntry: Integer)
    begin
        AnalysisViewBudgetEntry.SetRange("Analysis View Code", AnalysisView.Code);
        AnalysisViewBudgetEntry.SetFilter("Entry No.", '>=%1', DeleteFromEntry);
        AnalysisViewBudgetEntry.DeleteAll();
        AnalysisViewBudgetEntry.Reset();

        if AnalysisView."Account Filter" <> '' then
            GLBudgetEntry.SetFilter("G/L Account No.", AnalysisView."Account Filter");
        if AnalysisView."Business Unit Filter" <> '' then
            GLBudgetEntry.SetFilter("Business Unit Code", AnalysisView."Business Unit Filter");
        if not GLBudgetEntry.FindSet(true) then
            exit;

        repeat
            if DimSetIDInFilter(GLBudgetEntry."Dimension Set ID", AnalysisView) then
                UpdateAnalysisViewBudgetEntry(
                  GetDimVal(AnalysisView."Dimension 1 Code", GLBudgetEntry."Dimension Set ID"),
                  GetDimVal(AnalysisView."Dimension 2 Code", GLBudgetEntry."Dimension Set ID"),
                  GetDimVal(AnalysisView."Dimension 3 Code", GLBudgetEntry."Dimension Set ID"),
                  GetDimVal(AnalysisView."Dimension 4 Code", GLBudgetEntry."Dimension Set ID"));
            if ShowProgressWindow then
                UpdateWindowCounter(GLBudgetEntry."Entry No.");
        until GLBudgetEntry.Next() = 0;
        if ShowProgressWindow then
            UpdateWindowCounter(GLBudgetEntry."Entry No.");
        FlushAnalysisViewBudgetEntry();
    end;

    procedure UpdateAnalysisViewEntry(AccNo: Code[20]; CashFlowForecastNo: Code[20]; DimValue1: Code[20]; DimValue2: Code[20]; DimValue3: Code[20]; DimValue4: Code[20]; PostingDate: Date; Amount: Decimal; DebitAmount: Decimal; CreditAmount: Decimal; EntryNo: Integer)
    begin
        if PostingDate < AnalysisView."Starting Date" then begin
            PostingDate := AnalysisView."Starting Date" - 1;
            if AnalysisView."Date Compression" <> AnalysisView."Date Compression"::None then
                EntryNo := 0;
        end else begin
            PostingDate := CalculatePeriodStart(PostingDate, AnalysisView."Date Compression");
            if PostingDate < AnalysisView."Starting Date" then
                PostingDate := AnalysisView."Starting Date";
            if AnalysisView."Date Compression" <> AnalysisView."Date Compression"::None then
                EntryNo := 0;
        end;
        TempAnalysisViewEntry."Analysis View Code" := AnalysisView.Code;
        TempAnalysisViewEntry."Account Source" := AnalysisView."Account Source";
        TempAnalysisViewEntry."Account No." := AccNo;
        TempAnalysisViewEntry."Cash Flow Forecast No." := CashFlowForecastNo;
        TempAnalysisViewEntry."Posting Date" := PostingDate;
        TempAnalysisViewEntry."Dimension 1 Value Code" := DimValue1;
        TempAnalysisViewEntry."Dimension 2 Value Code" := DimValue2;
        TempAnalysisViewEntry."Dimension 3 Value Code" := DimValue3;
        TempAnalysisViewEntry."Dimension 4 Value Code" := DimValue4;
        TempAnalysisViewEntry."Entry No." := EntryNo;

        if TempAnalysisViewEntry.Find() then begin
            TempAnalysisViewEntry.Amount += Amount;
            TempAnalysisViewEntry."Debit Amount" += DebitAmount;
            TempAnalysisViewEntry."Credit Amount" += CreditAmount;
            TempAnalysisViewEntry.Modify();
        end else begin
            TempAnalysisViewEntry.Amount := Amount;
            TempAnalysisViewEntry."Debit Amount" := DebitAmount;
            TempAnalysisViewEntry."Credit Amount" := CreditAmount;
            TempAnalysisViewEntry.Insert();
            NoOfEntries := NoOfEntries + 1;
        end;
        if NoOfEntries >= 10000 then
            FlushAnalysisViewEntry();
    end;

    local procedure UpdateAnalysisViewBudgetEntry(DimValue1: Code[20]; DimValue2: Code[20]; DimValue3: Code[20]; DimValue4: Code[20])
    begin
        TempAnalysisViewBudgetEntry."Analysis View Code" := AnalysisView.Code;
        TempAnalysisViewBudgetEntry."Budget Name" := GLBudgetEntry."Budget Name";
        TempAnalysisViewBudgetEntry."Business Unit Code" := GLBudgetEntry."Business Unit Code";
        TempAnalysisViewBudgetEntry."G/L Account No." := GLBudgetEntry."G/L Account No.";
        if GLBudgetEntry.Date < AnalysisView."Starting Date" then
            TempAnalysisViewBudgetEntry."Posting Date" := AnalysisView."Starting Date" - 1
        else begin
            TempAnalysisViewBudgetEntry."Posting Date" :=
              CalculatePeriodStart(GLBudgetEntry.Date, AnalysisView."Date Compression");
            if TempAnalysisViewBudgetEntry."Posting Date" < AnalysisView."Starting Date" then
                TempAnalysisViewBudgetEntry."Posting Date" := AnalysisView."Starting Date";
        end;
        TempAnalysisViewBudgetEntry."Dimension 1 Value Code" := DimValue1;
        TempAnalysisViewBudgetEntry."Dimension 2 Value Code" := DimValue2;
        TempAnalysisViewBudgetEntry."Dimension 3 Value Code" := DimValue3;
        TempAnalysisViewBudgetEntry."Dimension 4 Value Code" := DimValue4;
        TempAnalysisViewBudgetEntry."Entry No." := GLBudgetEntry."Entry No.";

        if TempAnalysisViewBudgetEntry.Find() then begin
            TempAnalysisViewBudgetEntry.Amount := TempAnalysisViewBudgetEntry.Amount + GLBudgetEntry.Amount;
            TempAnalysisViewBudgetEntry.Modify();
        end else begin
            TempAnalysisViewBudgetEntry.Amount := GLBudgetEntry.Amount;
            TempAnalysisViewBudgetEntry.Insert();
            NoOfEntries := NoOfEntries + 1;
        end;
        if NoOfEntries >= 10000 then
            FlushAnalysisViewBudgetEntry();
    end;

    procedure CalculatePeriodStart(PostingDate: Date; DateCompression: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if PostingDate = ClosingDate(PostingDate) then
            exit(PostingDate);

        case DateCompression of
            AnalysisView."Date Compression"::Week:
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            AnalysisView."Date Compression"::Month:
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            AnalysisView."Date Compression"::Quarter:
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            AnalysisView."Date Compression"::Year:
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            AnalysisView."Date Compression"::Period:
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast() then
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    procedure FlushAnalysisViewEntry()
    begin
        if ShowProgressWindow then
            Window.Update(6, Text011);
        if TempAnalysisViewEntry.FindSet() then
            repeat
                AnalysisViewEntry.Init();
                AnalysisViewEntry := TempAnalysisViewEntry;
                if not AnalysisViewEntry.Insert() then begin
                    AnalysisViewEntry.Find();
                    AnalysisViewEntry.Amount += TempAnalysisViewEntry.Amount;
                    AnalysisViewEntry."Debit Amount" += TempAnalysisViewEntry."Debit Amount";
                    AnalysisViewEntry."Credit Amount" += TempAnalysisViewEntry."Credit Amount";
                    AnalysisViewEntry."Add.-Curr. Amount" += TempAnalysisViewEntry."Add.-Curr. Amount";
                    AnalysisViewEntry."Add.-Curr. Debit Amount" += TempAnalysisViewEntry."Add.-Curr. Debit Amount";
                    AnalysisViewEntry."Add.-Curr. Credit Amount" += TempAnalysisViewEntry."Add.-Curr. Credit Amount";
                    AnalysisViewEntry.Modify();
                end;
            until TempAnalysisViewEntry.Next() = 0;
        TempAnalysisViewEntry.DeleteAll();
        NoOfEntries := 0;
        if ShowProgressWindow then
            Window.Update(6, Text010);
    end;

    procedure FlushAnalysisViewBudgetEntry()
    begin
        if ShowProgressWindow then
            Window.Update(6, Text011);
        if TempAnalysisViewBudgetEntry.FindSet() then
            repeat
                AnalysisViewBudgetEntry.Init();
                AnalysisViewBudgetEntry := TempAnalysisViewBudgetEntry;
                if not AnalysisViewBudgetEntry.Insert() then begin
                    AnalysisViewBudgetEntry.Find();
                    AnalysisViewBudgetEntry.Amount += TempAnalysisViewBudgetEntry.Amount;
                    AnalysisViewBudgetEntry.Modify();
                end;
            until TempAnalysisViewBudgetEntry.Next() = 0;
        TempAnalysisViewBudgetEntry.DeleteAll();
        NoOfEntries := 0;
        if ShowProgressWindow then
            Window.Update(6, Text010);
    end;

    procedure GetDimVal(DimCode: Code[20]; DimSetID: Integer): Code[20]
    begin
        if TempDimSetEntry.Get(DimSetID, DimCode) then
            exit(TempDimSetEntry."Dimension Value Code");
        if DimSetEntry.Get(DimSetID, DimCode) then
            TempDimSetEntry := DimSetEntry
        else begin
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Code" := DimCode;
            TempDimSetEntry."Dimension Value Code" := '';
        end;
        TempDimSetEntry.Insert();
        exit(TempDimSetEntry."Dimension Value Code");
    end;

    local procedure InitWindow()
    begin
        Window.Open(
          Text005 +
          Text006 +
          Text009 +
          Text007 +
          Text008);
        Window.Update(6, Text010);
    end;

    procedure UpdateWindowCounter(EntryNo: Integer)
    begin
        WinUpdateCounter := WinUpdateCounter + 1;
        WinTime2 := Time;
        if (WinTime2 > WinTime1 + 1000) or (EntryNo = WinLastEntryNo) then begin
            if WinLastEntryNo <> 0 then
                Window.Update(3, Round(EntryNo / WinLastEntryNo * 10000, 1));
            WinTotalCounter := WinTotalCounter + WinUpdateCounter;
            if WinTime2 <> WinTime1 then
                Window.Update(4, Round(WinUpdateCounter * (1000 / (WinTime2 - WinTime1)), 1));
            if WinTime2 <> WinTime0 then
                Window.Update(5, Round(WinTotalCounter * (1000 / (WinTime2 - WinTime0)), 1));
            WinTime1 := WinTime2;
            WinUpdateCounter := 0;
        end;
    end;

    procedure UpdateWindowHeader(TableID: Integer; EntryNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        WinLastEntryNo := EntryNo;
        WinTotalCounter := 0;
        AllObj.Get(AllObj."Object Type"::Table, TableID);
        Window.Update(1, AnalysisView.Code);
        Window.Update(2, AllObj."Object Name");
        Window.Update(3, 0);
        Window.Update(4, 0);
        Window.Update(5, 0);
        WinTime0 := Time;
        WinTime1 := WinTime0;
        WinTime2 := WinTime0;
    end;

    procedure SetLastBudgetEntryNo(NewLastBudgetEntryNo: Integer)
    var
        AnalysisView2: Record "Analysis View";
    begin
        AnalysisView.SetRange("Last Budget Entry No.", NewLastBudgetEntryNo + 1, 2147483647);
        AnalysisView.SetRange("Include Budgets", true);
        if AnalysisView.FindSet() then
            repeat
                AnalysisView2 := AnalysisView;
                AnalysisView2."Last Budget Entry No." := NewLastBudgetEntryNo;
                AnalysisView2.Modify();
            until AnalysisView.Next() = 0;
    end;

    local procedure IsValueIncludedInFilter(DimValue: Code[20]; DimFilter: Code[250]): Boolean
    begin
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        TempDimBuf.Init();
        TempDimBuf."Dimension Value Code" := DimValue;
        TempDimBuf.Insert();
        TempDimBuf.SetFilter("Dimension Value Code", DimFilter);
        exit(TempDimBuf.FindFirst());
    end;

    procedure DimSetIDInFilter(DimSetID: Integer; var AnalysisView: Record "Analysis View"): Boolean
    var
        InFilters: Boolean;
    begin
        if not FilterIsInitialized then begin
            TempDimEntryBuffer.DeleteAll();
            FilterIsInitialized := true;
            AnalysisViewFilter.SetRange("Analysis View Code", AnalysisView.Code);
            FiltersExist := not AnalysisViewFilter.IsEmpty();
        end;
        if not FiltersExist then
            exit(true);

        if TempDimEntryBuffer.Get(DimSetID) then  // cashed value?
            exit(TempDimEntryBuffer."Dimension Entry No." <> 0);

        InFilters := true;
        if AnalysisViewFilter.FindSet() then
            repeat
                if DimSetEntry.Get(DimSetID, AnalysisViewFilter."Dimension Code") then
                    InFilters :=
                      InFilters and IsValueIncludedInFilter(DimSetEntry."Dimension Value Code", AnalysisViewFilter."Dimension Value Filter")
                else
                    InFilters :=
                      InFilters and IsValueIncludedInFilter('', AnalysisViewFilter."Dimension Value Filter");
            until (AnalysisViewFilter.Next() = 0) or not InFilters;
        TempDimEntryBuffer."No." := DimSetID;
        if InFilters then
            TempDimEntryBuffer."Dimension Entry No." := 1
        else
            TempDimEntryBuffer."Dimension Entry No." := 0;
        TempDimEntryBuffer.Insert();
        exit(InFilters);
    end;
}

