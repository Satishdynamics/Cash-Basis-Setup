report 50050 "SLGI CSH Calculate Cash Basis"
{
    Permissions = tabledata 50050 = rmid;

    Caption = 'Calculate Cash Basis';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(CLE; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code")
                                where("Document Type" = filter(Payment | "Credit Memo" | Refund));

            trigger OnAfterGetRecord();
            begin

                CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                AppliedAmt := "Amount (LCY)" - "Remaining Amt. (LCY)";

                if AppliedAmt <> 0 then begin
                    //Look for applied entries and post them with "Payment Date"
                    FindAppliedDocsCLE(CLE);
                    FindAppliedPayDiscountCLE(CLE);

                end;

                //Nothing was applied or there was a remaining amount of any kind...
                if Abs("Remaining Amt. (LCY)") > 0 then
                    if "Document Type" in ["Document Type"::Payment, "Document Type"::Refund] then
                        PostRemainingAmountCLE(CLE, "Remaining Amt. (LCY)", false, false);

                Counter2 += Step;
                Win.Update(1, Round(Counter2, 1));
            end;

            trigger OnPreDataItem();
            begin
                //!SlgCash 2019.2
                if CashSetup."Ignore Before Date" <> 0D then
                    SetFilter("Posting Date", '%1..', CashSetup."Ignore Before Date");
                Counter := Count();
                if Counter <> 0 then
                    Step := 10000 / Counter;
                Counter := 0;
                Counter2 := 0;
                Win.Open(Text101 + Text100, Counter);
            end;
        }
        dataitem(VLE; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code")
                                order(ascending)
                                where("Document Type" = filter(Payment | "Credit Memo" | Refund));

            trigger OnAfterGetRecord();
            begin
                CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                AppliedAmt := "Amount (LCY)" - "Remaining Amt. (LCY)";

                if AppliedAmt <> 0 then begin
                    //Look for applied entries and post them with "Payment Date"
                    FindAppliedDocsVLE(VLE);
                    FindAppliedPayDiscountVLE(VLE);
                end;

                //Nothing was applied or there was a remaining amount of any kind...
                if Abs("Remaining Amt. (LCY)") > 0 then
                    if "Document Type" in ["Document Type"::Payment, "Document Type"::Refund] then
                        PostRemainingAmountVLE(VLE, "Remaining Amt. (LCY)", false, false);
                Counter2 += Step;
                Win.Update(1, Round(Counter2, 1));
            end;

            trigger OnPreDataItem();
            begin
                //!SlgCash 2019.2
                if CashSetup."Ignore Before Date" <> 0D then
                    SetFilter("Posting Date", '%1..', CashSetup."Ignore Before Date");
                Counter := Count();
                if Counter <> 0 then
                    Step := 10000 / Counter;
                Counter := 0;
                Counter2 := 0;
                Win.Open(Text102 + Text100, Counter);
            end;
        }
        dataitem(GLE; "G/L Entry")
        {
            DataItemTableView = sorting("SLGI CSH Exclude In Cash", "SLGI CSH Tax Entry")
                                where("SLGI CSH Tax Entry" = const(false),
                                      "SLGI CSH Exclude In Cash" = const(false));

            trigger OnAfterGetRecord();
            var
                GLA: Record "G/L Account";
            begin
                Counter2 += Step;
                Win.Update(1, Round(Counter2, 1));

                if (GLE."Document Type" in ["Document Type"::"Credit Memo", "Document Type"::Invoice, "Document Type"::"Finance Charge Memo", "Document Type"::Reminder]) and
                    not IncludeGLDocument(GLE) and not (GLE."Source Code" = SourceCodeSetup."Fixed Asset G/L Journal") then
                    exit;

                CGLE.Init;
                PostingDate := NormalDate(GLE."Posting Date");

                if (PostingDate <> GLE."Posting Date") or ("Source Code" in [SourceCodeSetup."Inventory Post Cost"]) then
                    exit;

                //!SC.CAH 112718
                if (GLE."Source Code" = SourceCodeSetup.Purchases) and (GLE."Source Type" = "Source Type"::"Fixed Asset")
                then
                    exit;

                //!SlgCash 2009 20090727 Modify this further so that skips if Source Type and Bal. Account Type do not match..
                // If both are vendor or both are customer, then we need to pull it in.  Assuming Vendors and Customers would not mix
                if not GLE."SLGI CSH Tax Entry" then
                    if (GLE."Source Type" in [GLE."Source Type"::Customer, GLE."Source Type"::Vendor])
                    then
                        //!SlgCash 2009 - New line..
                        if not (GLE."Bal. Account Type" in [GLE."Bal. Account Type"::Customer, GLE."Bal. Account Type"::Vendor]) then
                            exit;

                GLA.Get("G/L Account No.");
                CGLE."From Balance G/L" := GLA."Income/Balance" = GLA."Income/Balance"::"Balance Sheet";
                CGLE."G/L Account No." := GLE."G/L Account No.";
                CGLE."Document Type" := CGLE."Document Type"::"G/L Entry";
                CGLE."Document No." := GLE."Document No.";
                CGLE."Posting Date" := GLE."Posting Date";
                CGLE."Document Posting Date" := 0D;
                CGLE."Global Dimension 1 Code" := GLE."Global Dimension 1 Code";
                CGLE."Global Dimension 2 Code" := GLE."Global Dimension 2 Code";
                CGLE."Dimension Set ID" := GLE."Dimension Set ID";
                CGLE.Amount := GLE.Amount;
                CGLE."Payment No." := '';
                CGLE."GL Document Type" := GLE."Document Type";
                OnBeforePostCashEntry(GLA, GLE, CGLE);
                PostCashEntry(CGLE, true);
            end;

            trigger OnPostDataItem();
            begin
                Win.Close;
            end;

            trigger OnPreDataItem();
            begin
                if CashSetup."Ignore Before Date" <> 0D then
                    SetFilter("Posting Date", '%1..', CashSetup."Ignore Before Date");

                Counter := Count;

                if Counter <> 0 then
                    Step := 10000 / Counter;
                Counter := 0;
                Counter2 := 0;
                Win.Open(Text103 + Text100, Counter);
                SourceCodeSetup.Get;
            end;
        }
        dataitem(CALE; "SLGI Cash Adjust. Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");

            trigger OnAfterGetRecord();
            begin
                GLA.Get("G/L Account No.");
                CGLE.Init;

                PostingDate := NormalDate(CALE."Posting Date");
                CGLE."From Balance G/L" := GLA."Income/Balance" = GLA."Income/Balance"::"Balance Sheet";
                CGLE."G/L Account No." := CALE."G/L Account No.";
                CGLE."Posting Date" := CALE."Posting Date";
                CGLE."Document Type" := CGLE."Document Type"::Adjustment;
                CGLE."Document No." := CALE."Document No.";
                CGLE."Global Dimension 1 Code" := CALE."Shortcut Dimension 1 Code";
                CGLE."Global Dimension 2 Code" := CALE."Shortcut Dimension 2 Code";
                CGLE.Amount := CALE.Amount;
                CGLE."Payment No." := '';  //!SlgCash 2009 050609
                CGLE."Dimension Set ID" := CALE."Dimension Set ID";
                PostCashEntry(CGLE, true);

                Counter2 += Step;
                Win.Update(1, Round(Counter2, 1));
            end;

            trigger OnPostDataItem();
            begin
                Win.Close;
            end;

            trigger OnPreDataItem();
            begin
                //!SlgCash 2019.2
                if CashSetup."Ignore Before Date" <> 0D then
                    SetFilter("Posting Date", '%1..', CashSetup."Ignore Before Date");
                Counter := Count;
                if Counter <> 0 then
                    Step := 10000 / Counter;
                Counter := 0;
                Counter2 := 0;
                Win.Open(Text104 + Text100, Counter);
            end;
        }
        dataitem(CloseYears; Integer)
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord();
            var
                TempDimBuf: Record "Dimension Buffer" temporary;
                TempDimBuf2: Record "Dimension Buffer" temporary;
                EntryNo: Integer;
                GlobalDimVal1: Code[20];
                GlobalDimVal2: Code[20];
                NewDimensionID: Integer;
                AccountingPeriod: Record "Accounting Period";
                AccountingPeriod2: Record "Accounting Period";
            begin
                CGLE."Payment No." := '';

                AccountingPeriod.Reset;
                AccountingPeriod.SetRange("SLGI CSH New Cash Fiscal Year", true);
                if (CashSetup."Ignore Before Date" <> 0D) and CashSetup."Do Not Delete Before Date" then
                    AccountingPeriod.SetFilter("Starting Date", '%1..', CalcDate('1D', CashSetup."Ignore Before Date"));
                if AccountingPeriod.FindFirst then
                    repeat
                        CashYearEndDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");
                        CashYearStartDate := CalcDate('<-1Y>', AccountingPeriod."Starting Date");
                        if (AccountingPeriod2.Get(CalcDate('<-CM>', CashYearEndDate))) and (AccountingPeriod2."SLGI CSH Cash Closed") then begin
                            TotalAmount := 0;
                            GLA.SetRange("Income/Balance", GLA."Income/Balance"::"Income Statement");
                            GLA.SetRange("Account Type", GLA."Account Type"::Posting);
                            if GLA.FindFirst then
                                repeat
                                    GLA.SetRange("Date Filter", 0D, CashYearEndDate);
                                    GLA.CalcFields("SLGI CSH Balance at Date Cash");
                                    if GLA."SLGI CSH Balance at Date Cash" <> 0 then begin

                                        CGLE.SetRange("G/L Account No.", GLA."No.");
                                        CGLE.SetRange("Posting Date", CashYearStartDate, CashYearEndDate);
                                        if CGLE.FindFirst then
                                            repeat
                                                if ClosePerGlobalDimOnly and (ClosePerGlobalDim1) then begin
                                                    if ClosePerGlobalDim1 then begin
                                                        CGLE.SetRange("Global Dimension 1 Code", CGLE."Global Dimension 1 Code");
                                                        if ClosePerGlobalDim2 then
                                                            CGLE.SetRange("Global Dimension 2 Code", CGLE."Global Dimension 2 Code");
                                                    end;
                                                    CalcSumsInFilter;
                                                    EntryNo := CGLE."Entry No.";
                                                    GetCBEntryDimensions(EntryNo, TempDimBuf);
                                                end;

                                                if (CGLE.Amount <> 0) then begin
                                                    if not (ClosePerGlobalDimOnly and (ClosePerGlobalDim1)) then begin
                                                        TotalAmount += CGLE.Amount;

                                                        GetCBEntryDimensions(CGLE."Entry No.", TempDimBuf);
                                                    end;

                                                    TempDimBuf2.DeleteAll();
                                                    if TempSelectedDim.Find('-') then
                                                        repeat
                                                            if TempDimBuf.Get(Database::"SLGI Cash G/L Entry", CGLE."Entry No.", TempSelectedDim."Dimension Code")
                                                            then begin
                                                                TempDimBuf2."Table ID" := TempDimBuf."Table ID";
                                                                TempDimBuf2."Dimension Code" := TempDimBuf."Dimension Code";
                                                                TempDimBuf2."Dimension Value Code" := TempDimBuf."Dimension Value Code";
                                                                TempDimBuf2.Insert;
                                                            end;
                                                        until TempSelectedDim.Next = 0;

                                                    EntryNo := DimBufMgt.GetDimensionId(TempDimBuf2);

                                                    EntryNoAmountBuf.Reset;
                                                    EntryNoAmountBuf."Business Unit Code" := '';
                                                    EntryNoAmountBuf."Entry No." := EntryNo;
                                                    if EntryNoAmountBuf.Find then begin
                                                        EntryNoAmountBuf.Amount := EntryNoAmountBuf.Amount + CGLE.Amount;
                                                        EntryNoAmountBuf.Modify;
                                                    end else begin
                                                        EntryNoAmountBuf.Amount := CGLE.Amount;
                                                        EntryNoAmountBuf.Insert;
                                                    end;
                                                end;

                                                if ClosePerGlobalDimOnly and (ClosePerGlobalDim1) then begin
                                                    CGLE.FindLast;
                                                    if CGLE.FieldActive("Global Dimension 1 Code") then begin
                                                        CGLE.SetRange("Global Dimension 1 Code");
                                                        if CGLE.FieldActive("Global Dimension 2 Code") then
                                                            CGLE.SetRange("Global Dimension 2 Code");
                                                    end
                                                end;
                                            until CGLE.Next = 0;
                                    end;

                                    //Inserting Entries
                                    EntryNoAmountBuf.Reset;
                                    MaxEntry := EntryNoAmountBuf.Count;
                                    EntryCount := 0;

                                    if EntryNoAmountBuf.Find('-') then
                                        repeat
                                            EntryCount := EntryCount + 1;

                                            if (EntryNoAmountBuf.Amount <> 0) then begin

                                                Clear(CGLE);
                                                CGLE."Document Type" := CGLE."Document Type"::"G/L Entry";
                                                CGLE."G/L Account No." := GLA."No.";
                                                CGLE."Posting Date" := ClosingDate(CashYearEndDate);
                                                CGLE.Amount := -EntryNoAmountBuf.Amount;
                                                TotalAmount += -EntryNoAmountBuf.Amount;
                                                CGLE."Document No." := 'System Generated';  //!SlgCash 2009 050609
                                                TempDimBuf2.DeleteAll;
                                                DimBufMgt.RetrieveDimensions(EntryNoAmountBuf."Entry No.", TempDimBuf2);
                                                NewDimensionID := DimMgt.CreateDimSetIDFromDimBuf(TempDimBuf2);
                                                CGLE."Dimension Set ID" := NewDimensionID;
                                                DimMgt.UpdateGlobalDimFromDimSetID(NewDimensionID, GlobalDimVal1, GlobalDimVal2);
                                                CGLE."Global Dimension 1 Code" := '';
                                                if ClosePerGlobalDim1 then
                                                    CGLE."Global Dimension 1 Code" := GlobalDimVal1;
                                                CGLE."Global Dimension 2 Code" := '';
                                                if ClosePerGlobalDim2 then
                                                    CGLE."Global Dimension 2 Code" := GlobalDimVal2;

                                                PostCashEntry(CGLE, false);
                                                TotalAmount += CGLE.Amount;

                                            end;
                                        until EntryNoAmountBuf.Next = 0;

                                    EntryNoAmountBuf.DeleteAll;

                                until GLA.Next = 0;
                            // Post to retained earnings
                            Clear(CGLE);
                            CGLE."Document Type" := CGLE."Document Type"::"G/L Entry";
                            CGLE."G/L Account No." := CashSetup."Retained Earnings";
                            CGLE."Posting Date" := ClosingDate(CashYearEndDate);
                            CGLE."Document No." := 'System Generated';  //!SlgCash 2009 050609
                            CGLE.Amount := -TotalAmount;
                            PostCashEntry(CGLE, false);
                        end;
                    until AccountingPeriod.Next = 0;
            end;

            trigger OnPreDataItem();
            begin

                MaxEntry := Count;

                EntryNoAmountBuf.DeleteAll;
                EntryCount := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {
                field(Dimensions; ColumnDim)
                {
                    AssistEdit = true;
                    ApplicationArea = All;
                    Editable = false;

                    Caption = 'Select Dimensions to Close';
                    trigger OnAssistEdit()
                    var
                        TempSelectedDim2: Record "Selected Dimension" temporary;
                        s: Text[1024];
                    begin
                        DimSelectionBuf.SetDimSelectionMultiple(3, Report::"SLGI CSH Calculate Cash Basis", ColumnDim);

                        SelectedDim.GetSelectedDim(CopyStr(UserId(), 1, 50), 3, Report::"SLGI CSH Calculate Cash Basis", '', TempSelectedDim2);
                        s := CheckDimPostingRules(TempSelectedDim2);
                        if s <> '' then
                            Message(s);
                    end;
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage();
        begin
            ColumnDim := DimSelectionBuf.GetDimSelectionText(3, Report::"SLGI CSH Calculate Cash Basis", '');
        end;
    }

    labels
    {
    }

    trigger OnPostReport();
    var
        AnalysisView: Record "Analysis View";
        UpdateAnalsysisView: Codeunit "SLGI CSH Update Analysis View";
    begin
        AnalysisView.SetRange("SLGI CSH Cash Basis", true);
        AnalysisView.SetRange("SLGI CSH Update on Cash Calc", true);
        if AnalysisView.FindSet() then
            repeat
                UpdateAnalsysisView.Run(AnalysisView);
            until AnalysisView.Next() = 0;
    end;

    trigger OnPreReport();
    var
        Dim: Record Dimension;
    // SlgCrestSub: Codeunit "SLGI SUB Subscription";
    begin
        //SlgCrestSub.CheckProductEnabled('CSH');
        CreatedOnDate := Today();

        CashSetup.Get();
        CashSetup.TestField("Retained Earnings");
        CashSetup.TestField("Overpayment Account");


        //Select All Dim
        //Dim.Blocked,false
        if Dim.FindFirst then
            repeat
                TempSelectedDim."Dimension Code" := Dim.Code;
                TempSelectedDim.Insert;
            until Dim.Next = 0;

        if CashSetup."Do Not Delete Before Date" and (CashSetup."Ignore Before Date" <> 0D) then begin
            CGLE.SetCurrentKey("Posting Date");
            CGLE.SetFilter("Posting Date", '%1..', CashSetup."Ignore Before Date");
        end;
        CGLE.LockTable;
        CGLE.DeleteAll;
        CGLE.Reset;


        ClosePerGlobalDim1 := false;
        ClosePerGlobalDim2 := false;
        ClosePerGlobalDimOnly := true;
        GLSetup.Get();

        if TempSelectedDim.FindFirst() then
            repeat
                if TempSelectedDim."Dimension Code" = GLSetup."Global Dimension 1 Code" then
                    ClosePerGlobalDim1 := true;
                if TempSelectedDim."Dimension Code" = GLSetup."Global Dimension 2 Code" then
                    ClosePerGlobalDim2 := true;
                if (TempSelectedDim."Dimension Code" <> GLSetup."Global Dimension 1 Code") and
                   (TempSelectedDim."Dimension Code" <> GLSetup."Global Dimension 2 Code")
                then
                    ClosePerGlobalDimOnly := false;
            until TempSelectedDim.Next = 0;

        OnFinishPreReport(TempSelectedDim, CGLE);
    end;

    var
        CGLE: Record "SLGI Cash G/L Entry";
        CreatedOnDate: Date;
        Counter: Integer;
        Counter2: Decimal;
        Win: Dialog;
        Step: Decimal;
        CashYearStartDate: Date;
        CashYearEndDate: Date;
        GLA: Record "G/L Account";
        PostingDate: Date;
        GLSetup: Record "General Ledger Setup";
        AppliedAmt: Decimal;
        CurrExchRate: Record "Currency Exchange Rate";
        AmountLCY: Decimal;
        SourceCodeSetup: Record "Source Code Setup";
        Text100: Label '@1@@@@@@@@@@@@@@@@@@@';
        Text101: Label '"Calculation A/R: "';
        Text102: Label '"Calculation A/P: "';
        Text103: Label '"Calculation G/L: "';
        Text104: Label 'Calculation Cash Adjustment:';
        ColumnDim: Text[250];
        DimSelectionBuf: Record "Dimension Selection Buffer";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        Text020: Label 'The following G/L Accounts have mandatory dimension codes that have not been selected:';
        Text021: Label '\\In order to post to these accounts you must also select these dimensions:';
        ClosePerGlobalDim1: Boolean;
        ClosePerGlobalDim2: Boolean;
        ClosePerGlobalDimOnly: Boolean;
        EntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        EntryCount: Integer;
        MaxEntry: Integer;
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Text014: Label 'The fiscal year must be closed before the income statement can be closed.';
        Text015: Label 'The fiscal year does not exist.';
        EndDateReqx: Date;
        TotalAmount: Decimal;
        s: Integer;
        Text007: Label '\Do you want to continue?';
        CashSetup: Record "SLGI Cash Basis Setup";
        CashMgmt: Codeunit "SLGI Cash Basis Mgmt";
        gCashPCT: Decimal;


    local procedure IncludeGLEntryCustomer(GLE: Record "G/L Entry"): Boolean
    var
        CustPostGroup: Record "Customer Posting Group";
    begin
        // We check if this is an account receiveable account
        CustPostGroup.SetRange("Receivables Account", GLE."G/L Account No.");
        exit(CustPostGroup.IsEmpty());
    end;

    local procedure IncludeGLEntryVendor(GLE: Record "G/L Entry"): Boolean
    var
        VendPostGroup: Record "Vendor Posting Group";
    begin
        // We check if this is an account receiveable account
        VendPostGroup.SetRange("Payables Account", GLE."G/L Account No.");
        exit(VendPostGroup.IsEmpty());
    end;

    local procedure IncludeGLDocument(GLE: Record "G/L Entry"): Boolean
    var
        GLE2: Record "G/L Entry";
    begin
        if GLE."Source Code" = SourceCodeSetup."Fixed Asset G/L Journal" then
            exit(true);
        // Find G/L entries with a document type with no source types for the doc no.
        if GLE."Document Type" <> GLE."Document Type"::" " then begin
            GLE2.SetCurrentKey("Document Type", "Document No.");
            GLE2.SetRange("Document No.", GLE."Document No.");
            GLE2.SetRange("Document Type", GLE."Document Type");
            GLE2.SetRange("Posting Date", GLE."Posting Date");
            GLE2.SetFilter("Source Type", '<>%1', GLE2."Source Type"::" ");
            exit(GLE2.IsEmpty());
        end;
    end;

    local procedure CalcCashPCT(EntryAmount: Decimal; ParentAmount: Decimal): Decimal;
    var
        TempPCT: Decimal;
    begin
        TempPCT := Abs(EntryAmount / ParentAmount) * 100;
        if TempPCT > 100 then
            TempPCT := 100;

        exit(TempPCT);
    end;

    local procedure CalcCashAmount(CashAmount: Decimal): Decimal;
    var
        TempAmount: Decimal;
    begin

        TempAmount := CashAmount * gCashPCT / 100;
        exit(TempAmount);
    end;

    local procedure AddARCashEntry(CashAmount: Decimal; EntryAmount: Decimal);
    begin
        gCashPCT := CalcCashPCT(CashAmount, EntryAmount);
    end;

    local procedure AddAPCashEntry(EntryAmount: Decimal; CashAmount: Decimal);
    begin
        gCashPCT := CalcCashPCT(EntryAmount, CashAmount);
    end;

    local procedure ProcessCustGLE(GLE: Record "G/L Entry"; GLEDocType: Enum "Gen. Journal Document Type"; CashDocType: Enum "SLGI CSH Document Type"; DocCLE: Record "Cust. Ledger Entry"; AppliedCLE: Record "Cust. Ledger Entry"; AppliedDetail: Record "Detailed Cust. Ledg. Entry"; Reverse: Boolean)
    var
        Cust: Record Customer;
    begin
        GLE.SetCurrentKey("Document Type", "Document No.");
        GLE.SetRange("Document Type", GLEDocType);
        GLE.SetRange("Document No.", DocCLE."Document No.");
        GLE.SetRange("SLGI CSH Exclude In Cash", false);
        if GLE.FindSet() then
            repeat
                if IncludeGLEntryCustomer(GLE) then begin
                    Clear(CGLE);
                    CGLE."G/L Account No." := GLE."G/L Account No.";
                    GLA.Get(GLE."G/L Account No.");
                    if AppliedCLE."Document Type" in [AppliedCLE."Document Type"::Payment, AppliedCLE."Document Type"::Refund] then
                        CGLE."Posting Date" := AppliedCLE."Posting Date" //Payment Posting Date
                    else
                        CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date
                    CGLE."Document Type" := CashDocType;
                    CGLE."Document No." := GLE."Document No.";
                    CGLE."Document Posting Date" := DocCLE."Posting Date";
                    case AppliedCLE."Document Type" of
                        AppliedCLE."Document Type"::Payment:
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                        AppliedCLE."Document Type"::Invoice:
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Invoice";
                        AppliedCLE."Document Type"::"Credit Memo":
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Cr. Memo";
                        AppliedCLE."Document Type"::Refund:
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                    end;

                    CGLE."Applied Document No." := AppliedCLE."Document No.";
                    CGLE."Applied Date" := AppliedDetail."Posting Date";
                    CGLE."Global Dimension 1 Code" := GLE."Global Dimension 1 Code";
                    CGLE."Global Dimension 2 Code" := GLE."Global Dimension 2 Code";
                    CGLE."Dimension Set ID" := GLE."Dimension Set ID";

                    if GLE."Source Type" = GLE."Source Type"::Customer then
                        CGLE."Source Type" := CGLE."Source Type"::Customer;
                    CGLE."Source No." := GLE."Source No.";
                    if Cust.Get(GLE."Source No.") then
                        CGLE."Source Name" := Cust.Name;
                    CGLE.Amount := CalcCashAmount(GLE.Amount);

                    if AppliedCLE."Document Type" = AppliedCLE."Document Type"::Payment then
                        CGLE."Payment No." := AppliedCLE."Document No.";

                    if Reverse then
                        CGLE.Amount := -CGLE.Amount;

                    PostCashEntry(CGLE, false);
                end;
            until GLE.Next() = 0;
    end;

    local procedure ProcessVendGLE(GLE: Record "G/L Entry"; GLEDocType: Enum "Gen. Journal Document Type"; CashDocType: Enum "SLGI CSH Document Type"; DocCLE: Record "Vendor Ledger Entry"; AppliedVLE: Record "Vendor Ledger Entry"; AppliedDetail: Record "Detailed Vendor Ledg. Entry"; Reverse: Boolean)
    var
        Vend: Record Vendor;
    begin
        GLE.SetCurrentKey("Document Type", "Document No.");
        GLE.SetRange("Document Type", GLEDocType);
        GLE.SetRange("Document No.", DocCLE."Document No.");
        GLE.SetRange("SLGI CSH Exclude In Cash", false);
        if GLE.FindSet() and not GLE."SLGI CSH Exclude In Cash" then
            repeat
                if IncludeGLEntryVendor(GLE) then begin
                    Clear(CGLE);
                    CGLE."G/L Account No." := GLE."G/L Account No.";
                    GLA.Get(GLE."G/L Account No.");
                    if AppliedVLE."Document Type" in [AppliedVLE."Document Type"::Payment, AppliedVLE."Document Type"::Refund] then
                        CGLE."Posting Date" := AppliedVLE."Posting Date" //Payment Posting Date
                    else
                        CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date
                    CGLE."Document Type" := CashDocType;
                    CGLE."Document No." := GLE."Document No.";
                    CGLE."Document Posting Date" := DocCLE."Posting Date";
                    case AppliedVLE."Document Type" of
                        AppliedVLE."Document Type"::Payment:
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                        AppliedVLE."Document Type"::Invoice:
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Purchase Invoice";
                        AppliedVLE."Document Type"::"Credit Memo":
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Purchase Cr. Memo";
                        AppliedVLE."Document Type"::Refund:
                            CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                    end;

                    CGLE."Applied Document No." := AppliedVLE."Document No.";
                    CGLE."Applied Date" := AppliedDetail."Posting Date";
                    CGLE."Global Dimension 1 Code" := GLE."Global Dimension 1 Code";
                    CGLE."Global Dimension 2 Code" := GLE."Global Dimension 2 Code";
                    CGLE."Dimension Set ID" := GLE."Dimension Set ID";

                    if GLE."Source Type" = GLE."Source Type"::Vendor then
                        CGLE."Source Type" := CGLE."Source Type"::Vendor;
                    CGLE."Source No." := GLE."Source No.";
                    if Vend.Get(GLE."Source No.") then
                        CGLE."Source Name" := Vend.Name;
                    CGLE.Amount := CalcCashAmount(GLE.Amount);

                    if AppliedVLE."Document Type" = AppliedVLE."Document Type"::Payment then
                        CGLE."Payment No." := AppliedVLE."Document No.";

                    if Reverse then
                        CGLE.Amount := -CGLE.Amount;

                    PostCashEntry(CGLE, false);
                end;
            until GLE.Next() = 0;
    end;

    local procedure InsertSalesInvoice(InvoiceCLE: Record "Cust. Ledger Entry"; AppliedCLE: Record "Cust. Ledger Entry"; AppliedDetail: Record "Detailed Cust. Ledg. Entry"; Reverse: Boolean);
    var
        SIH: Record "Sales Invoice Header";
        SIL: Record "Sales Invoice Line";
        GPS: Record "General Posting Setup";
        CLE: Record "Cust. Ledger Entry";
        GLE: Record "G/L Entry";
        Cust: Record Customer;
    begin
        CGLE.Init;
        if SIH.Get(InvoiceCLE."Document No.") then begin
            SIL.SetRange("Document No.", SIH."No.");
            if SIL.Find('-') then
                repeat
                    if (SIL.Amount <> 0) and not (SIL.Type = SIL.Type::"Fixed Asset")
                    then begin
                        if SIL.Type <> SIL.Type::"G/L Account" then begin
                            GPS.Get(SIL."Gen. Bus. Posting Group", SIL."Gen. Prod. Posting Group");
                            CGLE."G/L Account No." := GPS."Sales Account";
                        end else
                            CGLE."G/L Account No." := SIL."No.";
                        GLA.Get(CGLE."G/L Account No.");

                        if AppliedCLE."Document Type" in [AppliedCLE."Document Type"::Payment, AppliedCLE."Document Type"::Refund] then
                            CGLE."Posting Date" := AppliedCLE."Posting Date" //Payment Posting Date
                        else
                            CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date

                        CGLE."Document Type" := CGLE."Document Type"::"Sales Invoice";
                        CGLE."Document No." := SIL."Document No.";
                        CGLE."Document Posting Date" := InvoiceCLE."Posting Date";

                        case AppliedCLE."Document Type" of
                            AppliedCLE."Document Type"::Payment:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                            AppliedCLE."Document Type"::Invoice:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Invoice";
                            AppliedCLE."Document Type"::"Credit Memo":
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Cr. Memo";
                            AppliedCLE."Document Type"::Refund:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                        end;

                        CGLE."Applied Document No." := AppliedCLE."Document No.";
                        CGLE."Applied Date" := AppliedDetail."Posting Date";


                        CGLE."Global Dimension 1 Code" := SIL."Shortcut Dimension 1 Code";
                        CGLE."Global Dimension 2 Code" := SIL."Shortcut Dimension 2 Code";
                        //!SC 2014
                        CGLE."Dimension Set ID" := SIL."Dimension Set ID";

                        CGLE."Source Type" := CGLE."Source Type"::Customer;
                        CGLE."Source No." := SIH."Sell-to Customer No.";
                        CGLE."Source Name" := SIH."Sell-to Customer Name";

                        if SIH."Currency Code" = '' then
                            AmountLCY := SIL.Amount
                        else
                            AmountLCY :=
                                     CurrExchRate.ExchangeAmtFCYToLCY(
                                       InvoiceCLE."Posting Date", SIH."Currency Code", SIL.Amount, SIH."Currency Factor");

                        CGLE.Amount := -CalcCashAmount(AmountLCY);

                        if AppliedCLE."Document Type" = AppliedCLE."Document Type"::Payment then
                            CGLE."Payment No." := AppliedCLE."Document No.";

                        if Reverse then
                            CGLE.Amount := -CGLE.Amount;

                        OnBeforePostCashEntrySalesInv(SIH, SIL, CGLE);
                        PostCashEntry(CGLE, false);
                    end;
                until SIL.Next = 0;

            //!SlgCash 2010 R2 - Find Tax Entries from GL
            FindTaxEntries(InvoiceCLE."Document Type", InvoiceCLE."Document No.", Reverse);
        end else
            ProcessCustGLE(GLE, Enum::"Gen. Journal Document Type"::Invoice, Enum::"SLGI CSH Document Type"::"Sales Invoice", InvoiceCLE, AppliedCLE, AppliedDetail, Reverse);
    end;

    local procedure InsertFinanceChargeMemo(FCMCLE: Record "Cust. Ledger Entry"; AppliedCLE: Record "Cust. Ledger Entry"; AppliedDetail: Record "Detailed Cust. Ledg. Entry"; Reverse: Boolean);
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        Cust: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        GLE: Record "G/L Entry";
    begin
        CGLE.Init();
        if IssuedFinChargeMemoHeader.Get(FCMCLE."Document No.") then begin
            Cust.Get(IssuedFinChargeMemoHeader."Customer No.");
            IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
            if IssuedFinChargeMemoLine.FindFirst() then
                repeat
                    if (IssuedFinChargeMemoLine.Amount <> 0) and (IssuedFinChargeMemoLine.Type <> IssuedFinChargeMemoLine.Type::" ") then begin
                        if IssuedFinChargeMemoLine.Type = IssuedFinChargeMemoLine.Type::"Customer Ledger Entry" then begin
                            CustPostGroup.Get(Cust."Customer Posting Group");
                            CustPostGroup.TestField("Interest Account");
                            CGLE."G/L Account No." := CustPostGroup."Interest Account";
                        end else
                            CGLE."G/L Account No." := IssuedFinChargeMemoLine."No.";
                        GLA.Get(CGLE."G/L Account No.");
                        if AppliedCLE."Document Type" in [AppliedCLE."Document Type"::Payment, AppliedCLE."Document Type"::Refund] then
                            CGLE."Posting Date" := AppliedCLE."Posting Date" //Payment Posting Date
                        else
                            CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date
                        CGLE."Document Type" := CGLE."Document Type"::"Fin.Charge Memo";
                        CGLE."Document No." := IssuedFinChargeMemoLine."Finance Charge Memo No.";
                        CGLE."Document Posting Date" := FCMCLE."Posting Date";
                        case AppliedCLE."Document Type" of
                            AppliedCLE."Document Type"::Payment:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                            AppliedCLE."Document Type"::Invoice:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Invoice";
                            AppliedCLE."Document Type"::"Credit Memo":
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Cr. Memo";
                            AppliedCLE."Document Type"::Refund:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                        end;
                        CGLE."Applied Document No." := AppliedCLE."Document No.";
                        CGLE."Applied Date" := AppliedDetail."Posting Date";
                        CGLE."Source Type" := CGLE."Source Type"::Customer;
                        CGLE."Source No." := IssuedFinChargeMemoHeader."Customer No.";
                        CGLE."Source Name" := IssuedFinChargeMemoHeader.Name;
                        if IssuedFinChargeMemoHeader."Currency Code" = '' then
                            AmountLCY := IssuedFinChargeMemoLine.Amount
                        else
                            AmountLCY :=
                                     CurrExchRate.ExchangeAmtFCYToLCY(
                                       FCMCLE."Posting Date", IssuedFinChargeMemoHeader."Currency Code", IssuedFinChargeMemoLine.Amount, 1);

                        CGLE.Amount := -CalcCashAmount(AmountLCY);
                        if AppliedCLE."Document Type" = AppliedCLE."Document Type"::Payment then
                            CGLE."Payment No." := AppliedCLE."Document No.";

                        if Reverse then
                            CGLE.Amount := -CGLE.Amount;

                        PostCashEntry(CGLE, false);
                    end;
                until IssuedFinChargeMemoLine.Next() = 0;
            FindTaxEntries(FCMCLE."Document Type", FCMCLE."Document No.", Reverse);
        end else
            ProcessCustGLE(GLE, Enum::"Gen. Journal Document Type"::"Finance Charge Memo", Enum::"SLGI CSH Document Type"::"Fin.Charge Memo", FCMCLE, AppliedCLE, AppliedDetail, Reverse);
    end;

    local procedure InsertReminder(RemindCLE: Record "Cust. Ledger Entry"; AppliedCLE: Record "Cust. Ledger Entry"; AppliedDetail: Record "Detailed Cust. Ledg. Entry"; Reverse: Boolean);
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        Cust: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        GLE: Record "G/L Entry";
    begin
        CGLE.Init();
        if IssuedReminderHeader.Get(RemindCLE."Document No.") then begin
            Cust.Get(IssuedReminderHeader."Customer No.");
            IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
            if IssuedReminderLine.FindFirst() then
                repeat
                    if (IssuedReminderLine.Amount <> 0) and (IssuedReminderLine.Type <> IssuedReminderLine.Type::" ") then begin
                        if IssuedReminderLine.Type = IssuedReminderLine.Type::"Customer Ledger Entry" then begin
                            CustPostGroup.Get(Cust."Customer Posting Group");
                            CustPostGroup.TestField("Interest Account");
                            CGLE."G/L Account No." := CustPostGroup."Interest Account";
                        end else
                            CGLE."G/L Account No." := IssuedReminderLine."No.";
                        GLA.Get(CGLE."G/L Account No.");
                        if AppliedCLE."Document Type" in [AppliedCLE."Document Type"::Payment, AppliedCLE."Document Type"::Refund] then
                            CGLE."Posting Date" := AppliedCLE."Posting Date" //Payment Posting Date
                        else
                            CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date
                        CGLE."Document Type" := CGLE."Document Type"::Reminder;
                        CGLE."Document No." := IssuedReminderLine."Reminder No.";
                        CGLE."Document Posting Date" := RemindCLE."Posting Date";
                        case AppliedCLE."Document Type" of
                            AppliedCLE."Document Type"::Payment:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                            AppliedCLE."Document Type"::Invoice:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Invoice";
                            AppliedCLE."Document Type"::"Credit Memo":
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Cr. Memo";
                            AppliedCLE."Document Type"::Refund:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                        end;
                        CGLE."Applied Document No." := AppliedCLE."Document No.";
                        CGLE."Applied Date" := AppliedDetail."Posting Date";
                        CGLE."Source Type" := CGLE."Source Type"::Customer;
                        CGLE."Source No." := IssuedReminderHeader."Customer No.";
                        CGLE."Source Name" := IssuedReminderHeader.Name;
                        if IssuedReminderHeader."Currency Code" = '' then
                            AmountLCY := IssuedReminderLine.Amount
                        else
                            AmountLCY :=
                                     CurrExchRate.ExchangeAmtFCYToLCY(
                                       RemindCLE."Posting Date", IssuedReminderHeader."Currency Code", IssuedReminderLine.Amount, 1);

                        CGLE.Amount := -CalcCashAmount(AmountLCY);
                        if AppliedCLE."Document Type" = AppliedCLE."Document Type"::Payment then
                            CGLE."Payment No." := AppliedCLE."Document No.";

                        if Reverse then
                            CGLE.Amount := -CGLE.Amount;

                        PostCashEntry(CGLE, false);
                    end;
                until IssuedReminderLine.Next() = 0;
        end else
            ProcessCustGLE(GLE, Enum::"Gen. Journal Document Type"::Reminder, Enum::"SLGI CSH Document Type"::Reminder, RemindCLE, AppliedCLE, AppliedDetail, Reverse);
    end;

    local procedure InsertSalesCreditMemo(CrMemoCLE: Record "Cust. Ledger Entry"; AppliedCLE: Record "Cust. Ledger Entry"; AppliedDetail: Record "Detailed Cust. Ledg. Entry"; Reverse: Boolean);
    var
        SCH: Record "Sales Cr.Memo Header";
        SCL: Record "Sales Cr.Memo Line";
        GPS: Record "General Posting Setup";
        CLE: Record "Cust. Ledger Entry";
        GLE: Record "G/L Entry";
        Cust: Record Customer;
    begin
        CGLE.Init;
        if SCH.Get(CrMemoCLE."Document No.") then begin
            SCL.SetRange("Document No.", SCH."No.");
            if SCL.Find('-') then
                repeat
                    if (SCL.Amount <> 0) and not (SCL.Type = SCL.Type::"Fixed Asset") then begin
                        if SCL.Type <> SCL.Type::"G/L Account" then begin
                            GPS.Get(SCL."Gen. Bus. Posting Group", SCL."Gen. Prod. Posting Group");
                            GPS.TestField("Sales Credit Memo Account");
                            CGLE."G/L Account No." := GPS."Sales Credit Memo Account";
                        end else
                            CGLE."G/L Account No." := SCL."No.";
                        GLA.Get(CGLE."G/L Account No.");

                        if AppliedCLE."Document Type" in [AppliedCLE."Document Type"::Payment, AppliedCLE."Document Type"::Refund] then
                            CGLE."Posting Date" := AppliedCLE."Posting Date" //Payment Posting Date
                        else
                            CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date

                        CGLE."Document Type" := CGLE."Document Type"::"Sales Cr. Memo";
                        CGLE."Document No." := SCL."Document No.";
                        CGLE."Document Posting Date" := CrMemoCLE."Posting Date";

                        case AppliedCLE."Document Type" of
                            AppliedCLE."Document Type"::Payment:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                            AppliedCLE."Document Type"::Invoice:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Invoice";
                            AppliedCLE."Document Type"::"Credit Memo":
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Sales Cr. Memo";
                            AppliedCLE."Document Type"::Refund:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                        end;

                        CGLE."Applied Document No." := AppliedCLE."Document No.";
                        CGLE."Applied Date" := AppliedDetail."Posting Date";

                        CGLE."Global Dimension 1 Code" := SCL."Shortcut Dimension 1 Code";
                        CGLE."Global Dimension 2 Code" := SCL."Shortcut Dimension 2 Code";
                        CGLE."Dimension Set ID" := SCL."Dimension Set ID";

                        CGLE."Source Type" := CGLE."Source Type"::Customer;
                        CGLE."Source No." := SCH."Sell-to Customer No.";
                        CGLE."Source Name" := SCH."Sell-to Customer Name";

                        if SCH."Currency Code" = '' then
                            AmountLCY := SCL.Amount
                        else
                            AmountLCY :=
                                     CurrExchRate.ExchangeAmtFCYToLCY(
                                       CrMemoCLE."Posting Date", SCH."Currency Code", SCL.Amount, SCH."Currency Factor");
                        CGLE.Amount := CalcCashAmount(AmountLCY);
                        if AppliedCLE."Document Type" = AppliedCLE."Document Type"::Payment then
                            CGLE."Payment No." := AppliedCLE."Document No.";
                        if Reverse then
                            CGLE.Amount := -CGLE.Amount;
                        OnBeforePostCashEntrySalesCrM(SCH, SCL, CGLE);
                        PostCashEntry(CGLE, false);
                    end;
                until SCL.Next = 0;

            FindTaxEntries(CrMemoCLE."Document Type", CrMemoCLE."Document No.", Reverse);
        end else
            ProcessCustGLE(GLE, Enum::"Gen. Journal Document Type"::"Credit Memo", Enum::"SLGI CSH Document Type"::"Sales Cr. Memo", CrMemoCLE, AppliedCLE, AppliedDetail, Reverse);
    end;

    local procedure InsertPurchaseInvoice(InvoiceVLE: Record "Vendor Ledger Entry"; AppliedVLE: Record "Vendor Ledger Entry"; AppliedDetail: Record "Detailed Vendor Ledg. Entry"; Reverse: Boolean);
    var
        PIH: Record "Purch. Inv. Header";
        PIL: Record "Purch. Inv. Line";
        GPS: Record "General Posting Setup";
        VLE: Record "Vendor Ledger Entry";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CGLE.Init;
        if PIH.Get(InvoiceVLE."Document No.") then begin
            PIL.SetRange("Document No.", PIH."No.");
            if PIL.Find('-') then
                repeat
                    if (PIL.Amount <> 0) then begin
                        case PIL.Type of
                            PIL.Type::Item:
                                begin
                                    GPS.Get(PIL."Gen. Bus. Posting Group", PIL."Gen. Prod. Posting Group");
                                    Item.Get(PIL."No.");
                                    if Item.Type in [Item.Type::"Non-Inventory", Item.Type::Service] then
                                        CGLE."G/L Account No." := GPS."Purch. Account"
                                    else
                                        CGLE."G/L Account No." := GPS."COGS Account";
                                end;
                            PIL.Type::"Charge (Item)":
                                begin
                                    GPS.Get(PIL."Gen. Bus. Posting Group", PIL."Gen. Prod. Posting Group");
                                    CGLE."G/L Account No." := GPS."COGS Account";
                                end;
                            //!SC.CAH 112718
                            PIL.Type::"Fixed Asset":

                                case PIL."FA Posting Type" of
                                    PIL."FA Posting Type"::"Acquisition Cost":
                                        CGLE."G/L Account No." := GetFAcqusitionAccount(PIL."No.");
                                    PIL."FA Posting Type"::Appreciation:
                                        CGLE."G/L Account No." := GetFAAppreciationAccount(PIL."No.");
                                    PIL."FA Posting Type"::Maintenance:
                                        CGLE."G/L Account No." := GetFAMaintenanceAccount(PIL."No.");

                                end;
                            PIL.Type::"G/L Account":
                                CGLE."G/L Account No." := PIL."No.";
                        end;
                        GLA.Get(CGLE."G/L Account No.");

                        if PIH."SLGI CSH Overide Cash App Date" <> 0D then
                            CGLE."Posting Date" := PIH."SLGI CSH Overide Cash App Date"
                        else
                            if AppliedVLE."Document Type" in [AppliedVLE."Document Type"::Payment, AppliedVLE."Document Type"::Refund] then
                                CGLE."Posting Date" := AppliedVLE."Posting Date" //Payment Posting Date
                            else
                                CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date


                        CGLE."Document Type" := CGLE."Document Type"::"Purchase Invoice";
                        CGLE."Document No." := PIL."Document No.";
                        if PIH."SLGI CSH Overide Cash App Date" <> 0D then
                            CGLE."Document Posting Date" := PIH."SLGI CSH Overide Cash App Date"
                        else
                            CGLE."Document Posting Date" := InvoiceVLE."Posting Date";

                        case AppliedVLE."Document Type" of
                            AppliedVLE."Document Type"::Payment:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                            AppliedVLE."Document Type"::Invoice:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Purchase Invoice";
                            AppliedVLE."Document Type"::"Credit Memo":
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Purchase Cr. Memo";
                            AppliedVLE."Document Type"::Refund:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                        end;

                        CGLE."Applied Document No." := AppliedVLE."Document No.";
                        if PIH."SLGI CSH Overide Cash App Date" <> 0D then
                            CGLE."Applied Date" := PIH."SLGI CSH Overide Cash App Date"
                        else
                            CGLE."Applied Date" := AppliedDetail."Posting Date";

                        CGLE."Global Dimension 1 Code" := PIL."Shortcut Dimension 1 Code";
                        CGLE."Global Dimension 2 Code" := PIL."Shortcut Dimension 2 Code";
                        CGLE."Dimension Set ID" := PIL."Dimension Set ID";
                        CGLE."Source Type" := CGLE."Source Type"::Vendor;
                        CGLE."Source No." := PIH."Buy-from Vendor No.";
                        CGLE."Source Name" := PIH."Buy-from Vendor Name";
                        if PIH."Currency Code" = '' then
                            AmountLCY := PIL.Amount
                        else
                            AmountLCY :=
                                     CurrExchRate.ExchangeAmtFCYToLCY(
                                       InvoiceVLE."Posting Date", PIH."Currency Code", PIL.Amount, PIH."Currency Factor");

                        CGLE.Amount := CalcCashAmount(AmountLCY);
                        if Reverse then
                            CGLE.Amount := -CGLE.Amount;

                        if AppliedVLE."Document Type" = AppliedVLE."Document Type"::Payment then
                            CGLE."Payment No." := AppliedVLE."Document No.";

                        OnBeforePostCashEntryPurchaseInv(PIH, PIL, CGLE);
                        PostCashEntry(CGLE, false);
                    end;
                until PIL.Next = 0;
            FindTaxEntries(InvoiceVLE."Document Type", InvoiceVLE."Document No.", Reverse);
        end else
            ProcessVendGLE(GLE, Enum::"Gen. Journal Document Type"::Invoice, Enum::"SLGI CSH Document Type"::"Purchase Invoice", InvoiceVLE, AppliedVLE, AppliedDetail, Reverse);
    end;

    local procedure InsertPurchaseCreditMemo(CrMemoVLE: Record "Vendor Ledger Entry"; AppliedVLE: Record "Vendor Ledger Entry"; AppliedDetail: Record "Detailed Vendor Ledg. Entry"; Reverse: Boolean);
    var
        PCH: Record "Purch. Cr. Memo Hdr.";
        PCL: Record "Purch. Cr. Memo Line";
        GPS: Record "General Posting Setup";
        VLE: Record "Vendor Ledger Entry";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CGLE.Init;
        if PCH.Get(CrMemoVLE."Document No.") then begin
            PCL.SetRange("Document No.", PCH."No.");
            if PCL.Find('-') then
                repeat
                    if (PCL.Amount <> 0) then begin
                        case PCL.Type of
                            PCL.Type::Item:
                                begin
                                    GPS.Get(PCL."Gen. Bus. Posting Group", PCL."Gen. Prod. Posting Group");
                                    Item.Get(PCL."No.");
                                    if Item.Type in [Item.Type::"Non-Inventory", Item.Type::Service] then
                                        CGLE."G/L Account No." := GPS."Purch. Account"
                                    else
                                        CGLE."G/L Account No." := GPS."COGS Account";
                                end;
                            PCL.Type::"Charge (Item)":
                                begin
                                    GPS.Get(PCL."Gen. Bus. Posting Group", PCL."Gen. Prod. Posting Group");
                                    CGLE."G/L Account No." := GPS."COGS Account";
                                end;
                            //!SC.CAH 112718
                            PCL.Type::"Fixed Asset":

                                case PCL."FA Posting Type" of
                                    PCL."FA Posting Type"::"Acquisition Cost":
                                        CGLE."G/L Account No." := GetFAcqusitionAccount(PCL."No.");
                                    PCL."FA Posting Type"::Appreciation:
                                        CGLE."G/L Account No." := GetFAAppreciationAccount(PCL."No.");
                                    PCL."FA Posting Type"::Maintenance:
                                        CGLE."G/L Account No." := GetFAMaintenanceAccount(PCL."No.");
                                end;
                            PCL.Type::"G/L Account":
                                CGLE."G/L Account No." := PCL."No.";
                        end;
                        GLA.Get(CGLE."G/L Account No.");

                        if PCH."SLGI CSH Overide Cash App Date" <> 0D then
                            CGLE."Posting Date" := PCH."SLGI CSH Overide Cash App Date"
                        else
                            if AppliedVLE."Document Type" in [AppliedVLE."Document Type"::Payment, AppliedVLE."Document Type"::Refund] then
                                CGLE."Posting Date" := AppliedVLE."Posting Date" //Payment Posting Date
                            else
                                CGLE."Posting Date" := AppliedDetail."Posting Date"; //Actual Application Date

                        CGLE."Document Type" := CGLE."Document Type"::"Purchase Cr. Memo";
                        CGLE."Document No." := PCL."Document No.";
                        CGLE."Document Posting Date" := CrMemoVLE."Posting Date";

                        case AppliedVLE."Document Type" of
                            AppliedVLE."Document Type"::Payment:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Payment;
                            AppliedVLE."Document Type"::Invoice:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Purchase Invoice";
                            AppliedVLE."Document Type"::"Credit Memo":
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::"Purchase Cr. Memo";
                            AppliedVLE."Document Type"::Refund:
                                CGLE."Applied Document Type" := CGLE."Applied Document Type"::Refund;
                        end;

                        CGLE."Applied Document No." := AppliedVLE."Document No.";
                        CGLE."Applied Date" := AppliedDetail."Posting Date";
                        CGLE."Global Dimension 1 Code" := PCL."Shortcut Dimension 1 Code";
                        CGLE."Global Dimension 2 Code" := PCL."Shortcut Dimension 2 Code";
                        CGLE."Dimension Set ID" := PCL."Dimension Set ID";
                        CGLE."Source Type" := CGLE."Source Type"::Vendor;
                        CGLE."Source No." := PCH."Buy-from Vendor No.";
                        CGLE."Source Name" := PCH."Buy-from Vendor Name";
                        if PCH."Currency Code" = '' then
                            AmountLCY := PCL.Amount
                        else
                            AmountLCY :=
                                     CurrExchRate.ExchangeAmtFCYToLCY(
                                       CrMemoVLE."Posting Date", PCH."Currency Code", PCL.Amount, PCH."Currency Factor");
                        CGLE.Amount := -CalcCashAmount(AmountLCY);
                        if Reverse then     ////!SlgCash 2009 020609
                            CGLE.Amount := -CGLE.Amount;
                        if AppliedVLE."Document Type" = AppliedVLE."Document Type"::Payment then
                            CGLE."Payment No." := AppliedVLE."Document No.";
                        OnBeforePostCashEntryPurchaseCrM(PCH, PCL, CGLE);
                        PostCashEntry(CGLE, false);
                    end;
                until PCL.Next = 0;
            FindTaxEntries(CrMemoVLE."Document Type", CrMemoVLE."Document No.", Reverse);
        end else
            ProcessVendGLE(GLE, Enum::"Gen. Journal Document Type"::"Credit Memo", Enum::"SLGI CSH Document Type"::"Purchase Cr. Memo", CrMemoVLE, AppliedVLE, AppliedDetail, Reverse);
    end;

    procedure PostCashEntry(var CashEntry: Record "SLGI Cash G/L Entry"; ForceUseLedgerDim: Boolean);
    var
        CE: Record "SLGI Cash G/L Entry";
    begin
        CE.LockTable;
        if not CE.FindLast() then
            CE."Entry No." := 0;
        CashEntry."Entry No." := CE."Entry No." + 1;
        if CashEntry.Amount > 0 then begin
            CashEntry."Debit Amount" := CashEntry.Amount;
            CashEntry."Credit Amount" := 0;
        end else begin
            CashEntry."Credit Amount" := -CashEntry.Amount;
            CashEntry."Debit Amount" := 0
        end;
        CashEntry."Created On" := CreatedOnDate;

        CashEntry.Insert();
    end;

    local procedure PostRemainingAmountVLE(VLE: Record "Vendor Ledger Entry"; RemAmount: Decimal; Reverse: Boolean; ForceUseLedgerDim: Boolean);
    var
        Vendor: Record Vendor;
    begin
        if RemAmount <> 0 then begin
            CGLE.Init;
            CGLE."G/L Account No." := CashSetup."Overpayment Account";

            CGLE."Document Posting Date" := VLE."Posting Date";

            if VLE."Document Type" = VLE."Document Type"::Refund then
                CGLE."Document Type" := CGLE."Document Type"::Refund
            else
                CGLE."Document Type" := CGLE."Document Type"::Payment;

            CGLE."Posting Date" := VLE."Posting Date";

            CGLE."Document No." := VLE."Document No.";
            ;
            CGLE."Global Dimension 1 Code" := VLE."Global Dimension 1 Code";
            CGLE."Global Dimension 2 Code" := VLE."Global Dimension 2 Code";
            CGLE.Amount := VLE."Amount (LCY)";
            CGLE."Payment No." := VLE."Document No.";
            CGLE."Source Type" := CGLE."Source Type"::Vendor;
            CGLE."Source No." := VLE."Buy-from Vendor No.";
            if Vendor.Get(VLE."Buy-from Vendor No.") then
                CGLE."Source Name" := Vendor.Name
            else
                CGLE."Source Name" := '';

            if Reverse then
                RemAmount := -RemAmount;
            CGLE.Amount := RemAmount;
            PostCashEntry(CGLE, ForceUseLedgerDim);
        end;
    end;

    local procedure FindAppliedDocsVLE(VLE: Record "Vendor Ledger Entry");
    var
        DVLE: Record "Detailed Vendor Ledg. Entry";
        DVLE2: Record "Detailed Vendor Ledg. Entry";
        FoundVLE: Record "Vendor Ledger Entry";
        TEMPFoundApplied: Record "Detailed Vendor Ledg. Entry" temporary;
        AmtToPost: Decimal;
        bReverse: Boolean;
        bSkipOtherSide: Boolean;
    begin
        //Logic here mimicked from Form 62 Applied Vendor Entries - FindApplnEntriesDtldtLedgEntry

        DVLE.SetCurrentKey("Vendor Ledger Entry No.");
        DVLE.SetRange("Vendor Ledger Entry No.", VLE."Entry No.");
        DVLE.SetRange(Unapplied, false);
        if DVLE.FindFirst then
            repeat
                if DVLE."Vendor Ledger Entry No." = DVLE."Applied Vend. Ledger Entry No." then begin
                    DVLE2.Init;
                    DVLE2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DVLE2.SetRange("Applied Vend. Ledger Entry No.", DVLE."Applied Vend. Ledger Entry No.");
                    DVLE2.SetRange("Entry Type", DVLE2."Entry Type"::Application);
                    DVLE2.SetRange(Unapplied, false);
                    if DVLE2.Find('-') then
                        repeat
                            if DVLE2."Vendor Ledger Entry No." <> DVLE2."Applied Vend. Ledger Entry No." then begin
                                TEMPFoundApplied.Init;
                                TEMPFoundApplied.TransferFields(DVLE2);
                                if TEMPFoundApplied.Insert then;  //Ignore duplicates due to looping..
                            end;
                        until DVLE2.Next = 0;
                end else
                    if DVLE."Applied Vend. Ledger Entry No." <> 0 then begin
                        TEMPFoundApplied.Init;
                        TEMPFoundApplied.TransferFields(DVLE);
                        if TEMPFoundApplied.Insert then;  //Ignore duplicates due to looping..
                    end;
            until DVLE.Next = 0;


        //Now Loop through the marked (found documents and post them to Cash GL)
        if TEMPFoundApplied.FindFirst then
            repeat

                FoundVLE.SetCurrentKey("Entry No.");
                if VLE."Entry No." = TEMPFoundApplied."Vendor Ledger Entry No." then begin
                    FoundVLE.SetRange("Entry No.", TEMPFoundApplied."Applied Vend. Ledger Entry No.");
                    bReverse := true;
                end else begin
                    FoundVLE.SetRange("Entry No.", TEMPFoundApplied."Vendor Ledger Entry No.");
                    bReverse := false;
                end;
                FoundVLE.FindFirst;

                FoundVLE.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");

                AmtToPost := TEMPFoundApplied."Amount (LCY)";  //AppliedAmt;
                if bReverse then
                    AmtToPost := -AmtToPost;
                AddAPCashEntry(AmtToPost, FoundVLE."Amount (LCY)");
                bSkipOtherSide := false;
                case FoundVLE."Document Type" of
                    FoundVLE."Document Type"::Invoice:
                        begin
                            bReverse := AmtToPost < 0;
                            InsertPurchaseInvoice(FoundVLE, VLE, TEMPFoundApplied, bReverse);
                        end;
                    FoundVLE."Document Type"::"Credit Memo":
                        begin
                            bReverse := AmtToPost > 0;
                            InsertPurchaseCreditMemo(FoundVLE, VLE, TEMPFoundApplied, bReverse);
                        end;
                    FoundVLE."Document Type"::Payment,
                    FoundVLE."Document Type"::Reminder,
                    FoundVLE."Document Type"::Refund,
                    FoundVLE."Document Type"::" ":

                        //Ignore applied payments, as we should catch these already by the driving payment entries..
                        //Ignore Reminders
                        bSkipOtherSide := true;
                    else
                        Error('Unhandled VLE Document Type of %1! - While Processing VLE Entry No %2',
                            FoundVLE."Document Type", VLE."Entry No.");

                end;

                //Now Handle Other Side...
                if not bSkipOtherSide then begin

                    AddAPCashEntry(AmtToPost, VLE."Amount (LCY)");

                    case VLE."Document Type" of
                        VLE."Document Type"::Invoice:
                            begin
                                bReverse := AmtToPost > 0;
                                InsertPurchaseInvoice(VLE, FoundVLE, TEMPFoundApplied, bReverse);
                            end;
                        VLE."Document Type"::"Credit Memo":
                            begin
                                bReverse := AmtToPost < 0;
                                InsertPurchaseCreditMemo(VLE, FoundVLE, TEMPFoundApplied, bReverse);
                            end;
                        VLE."Document Type"::Payment,
                        VLE."Document Type"::Reminder,
                        VLE."Document Type"::Refund,
                        VLE."Document Type"::" ":
                            ;
                        //Ignore applied payments, as we should catch these already by the driving payment entries..
                        //Ignore Reminders
                        else
                            Error('Unhandled VLE Document Type of %1! - While Processing VLE Entry No %2',
                                VLE."Document Type", VLE."Entry No.");
                    end;
                end;
            until TEMPFoundApplied.Next = 0;

    end;

    procedure FindAppliedPayDiscountVLE(VLE: Record "Vendor Ledger Entry");
    var
        DVLE: Record "Detailed Vendor Ledg. Entry";
        GLA: Record "G/L Account";
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
    begin
        //!SlgCash 2010 R2
        DVLE.SetCurrentKey("Vendor Ledger Entry No.");
        DVLE.SetRange("Vendor Ledger Entry No.", VLE."Entry No.");
        DVLE.SetFilter("Entry Type", '%1|%2|%3', DVLE."Entry Type"::"Payment Discount", DVLE."Entry Type"::"Payment Discount Tolerance",
                                DVLE."Entry Type"::"Payment Tolerance");

        DVLE.SetRange(Unapplied, false);
        if DVLE.FindFirst then begin
            Vendor.Get(VLE."Vendor No.");
            VendPostingGroup.Get(Vendor."Vendor Posting Group");
            VendPostingGroup.TestField("Payment Disc. Credit Acc.");
            VendPostingGroup.TestField("Payment Tolerance Credit Acc.");
        end;

        if DVLE.FindFirst then
            repeat

                case DVLE."Entry Type" of
                    DVLE."Entry Type"::"Payment Discount":
                        GLA.Get(VendPostingGroup."Payment Disc. Credit Acc.");
                    DVLE."Entry Type"::"Payment Discount Tolerance":
                        GLA.Get(VendPostingGroup."Payment Tolerance Credit Acc.");
                    DVLE."Entry Type"::"Payment Tolerance":
                        GLA.Get(VendPostingGroup."Payment Tolerance Credit Acc.");
                end;

                CGLE."From Balance G/L" := GLA."Income/Balance" = GLA."Income/Balance"::"Balance Sheet";
                CGLE."G/L Account No." := GLA."No.";
                CGLE."Document Type" := CGLE."Document Type"::"G/L Entry";
                CGLE."Document No." := VLE."Document No.";
                CGLE."Posting Date" := VLE."Posting Date";
                CGLE."Document Posting Date" := 0D;
                CGLE."Global Dimension 1 Code" := VLE."Global Dimension 1 Code";
                CGLE."Global Dimension 2 Code" := VLE."Global Dimension 2 Code";

                CGLE.Amount := -DVLE.Amount;
                CGLE."Payment No." := '';

                CGLE."GL Document Type" := CGLE."GL Document Type"::Payment;

                //!SC 2014
                CGLE."Dimension Set ID" := VLE."Dimension Set ID";

                PostCashEntry(CGLE, true);

            until DVLE.Next = 0;
    end;

    procedure PostRemainingAmountCLE(CLE: Record "Cust. Ledger Entry"; RemAmount: Decimal; Reverse: Boolean; ForceUseLedgerDim: Boolean);
    var
        Customer: Record Customer;
    begin
        if RemAmount <> 0 then begin
            CGLE.Init;
            CGLE."G/L Account No." := CashSetup."Overpayment Account";
            CGLE."Document Posting Date" := CLE."Posting Date";

            if CLE."Document Type" = CLE."Document Type"::Refund then
                CGLE."Document Type" := CGLE."Document Type"::Refund
            else
                CGLE."Document Type" := CGLE."Document Type"::Payment;
            CGLE."Posting Date" := CLE."Posting Date";

            CGLE."Document No." := CLE."Document No.";
            ;
            CGLE."Global Dimension 1 Code" := CLE."Global Dimension 1 Code";
            CGLE."Global Dimension 2 Code" := CLE."Global Dimension 2 Code";
            CGLE.Amount := CalcCashAmount(CLE."Amount (LCY)");
            CGLE."Payment No." := CLE."Document No.";

            //!SC.Cash 2014.1 121216
            CGLE."Source Type" := CGLE."Source Type"::Customer;
            CGLE."Source No." := CLE."Customer No.";
            if Customer.Get(CLE."Customer No.") then
                CGLE."Source Name" := Customer.Name
            else
                CGLE."Source Name" := '';

            if Reverse then
                RemAmount := -RemAmount;
            CGLE.Amount := RemAmount;
            PostCashEntry(CGLE, ForceUseLedgerDim);
        end;
    end;

    procedure FindAppliedDocsCLE(CLE: Record "Cust. Ledger Entry");
    var
        DCLE: Record "Detailed Cust. Ledg. Entry";
        DCLE2: Record "Detailed Cust. Ledg. Entry";
        FoundCLE: Record "Cust. Ledger Entry";
        TEMPFoundApplied: Record "Detailed Cust. Ledg. Entry" temporary;
        AmtToPost: Decimal;
        bReverse: Boolean;
        bSkipOtherSide: Boolean;
    begin
        //Logic here mimicked from Form 61 Applied Customer Entries - FindApplnEntriesDtldtLedgEntry

        DCLE.SetCurrentKey("Cust. Ledger Entry No.");
        DCLE.SetRange("Cust. Ledger Entry No.", CLE."Entry No.");
        DCLE.SetRange(Unapplied, false);
        if DCLE.FindFirst then
            repeat
                if DCLE."Cust. Ledger Entry No." = DCLE."Applied Cust. Ledger Entry No." then begin
                    DCLE2.Init;
                    DCLE2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DCLE2.SetRange("Applied Cust. Ledger Entry No.", DCLE."Applied Cust. Ledger Entry No.");
                    DCLE2.SetRange("Entry Type", DCLE2."Entry Type"::Application);
                    DCLE2.SetRange(Unapplied, false);
                    if DCLE2.Find('-') then
                        repeat
                            if DCLE2."Cust. Ledger Entry No." <> DCLE2."Applied Cust. Ledger Entry No." then begin

                                TEMPFoundApplied.Init;
                                TEMPFoundApplied.TransferFields(DCLE2);
                                if TEMPFoundApplied.Insert then;  //Ignore duplicates due to looping..
                            end;
                        until DCLE2.Next = 0;
                end else
                    if DCLE."Applied Cust. Ledger Entry No." <> 0 then begin
                        TEMPFoundApplied.Init;
                        TEMPFoundApplied.TransferFields(DCLE);
                        if TEMPFoundApplied.Insert then;  //Ignore duplicates due to looping..
                    end;
            until DCLE.Next = 0;


        //Now Loop through the marked (found documents and post them to Cash GL)
        if TEMPFoundApplied.FindFirst then
            repeat

                FoundCLE.SetCurrentKey("Entry No.");
                if CLE."Entry No." = TEMPFoundApplied."Cust. Ledger Entry No." then begin
                    FoundCLE.SetRange("Entry No.", TEMPFoundApplied."Applied Cust. Ledger Entry No.");
                    bReverse := true;
                end else begin
                    FoundCLE.SetRange("Entry No.", TEMPFoundApplied."Cust. Ledger Entry No.");
                    bReverse := false;
                end;
                FoundCLE.FindFirst;

                FoundCLE.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");

                AmtToPost := TEMPFoundApplied."Amount (LCY)";  //AppliedAmt;
                if bReverse then
                    AmtToPost := -AmtToPost;
                AddARCashEntry(AmtToPost, FoundCLE."Amount (LCY)");
                bSkipOtherSide := false;
                case FoundCLE."Document Type" of
                    FoundCLE."Document Type"::Invoice:
                        begin
                            bReverse := AmtToPost > 0;
                            InsertSalesInvoice(FoundCLE, CLE, TEMPFoundApplied, bReverse);
                        end;
                    FoundCLE."Document Type"::"Credit Memo":
                        begin
                            bReverse := AmtToPost < 0;
                            InsertSalesCreditMemo(FoundCLE, CLE, TEMPFoundApplied, bReverse);
                        end;
                    FoundCLE."Document Type"::"Finance Charge Memo":
                        begin
                            bReverse := AmtToPost > 0;
                            InsertFinanceChargeMemo(FoundCLE, CLE, TEMPFoundApplied, bReverse);
                        end;
                    FoundCLE."Document Type"::Reminder:
                        begin
                            bReverse := AmtToPost > 0;
                            InsertReminder(FoundCLE, CLE, TEMPFoundApplied, bReverse);
                        end;
                    FoundCLE."Document Type"::Payment,
                    FoundCLE."Document Type"::Refund,
                    FoundCLE."Document Type"::" ":

                        //Ignore applied payments, as we should catch these already by the driving payment entries..
                        bSkipOtherSide := true;
                    else
                        Error('Unhandled CLE Document Type of %1! - While Processing CLE Entry No %2',
                             FoundCLE."Document Type", CLE."Entry No.");
                end;

                //Now Handle Other Side...
                if not bSkipOtherSide then begin
                    AddARCashEntry(AmtToPost, CLE."Amount (LCY)");
                    case CLE."Document Type" of
                        CLE."Document Type"::Invoice:
                            begin
                                bReverse := AmtToPost < 0;
                                InsertSalesInvoice(CLE, FoundCLE, TEMPFoundApplied, bReverse);
                            end;
                        CLE."Document Type"::"Credit Memo":
                            begin
                                bReverse := AmtToPost > 0;
                                InsertSalesCreditMemo(CLE, FoundCLE, TEMPFoundApplied, bReverse);
                            end;
                        CLE."Document Type"::"Finance Charge Memo":
                            begin
                                bReverse := AmtToPost < 0;
                                InsertFinanceChargeMemo(CLE, FoundCLE, TEMPFoundApplied, bReverse);
                            end;
                        CLE."Document Type"::Reminder:
                            begin
                                bReverse := AmtToPost < 0;
                                InsertReminder(CLE, FoundCLE, TEMPFoundApplied, bReverse);
                            end;
                        CLE."Document Type"::Payment,
                        CLE."Document Type"::Refund,
                        CLE."Document Type"::" ":
                            ;
                        //Ignore applied payments, as we should catch these already by the driving payment entries..
                        //Ignore Reminders
                        else
                            Error('Unhandled CLE Document Type of %1! - While Processing CLE Entry No %2',
                                 CLE."Document Type", CLE."Entry No.");
                    end;
                end;

            until TEMPFoundApplied.Next = 0;
    end;

    procedure FindAppliedPayDiscountCLE(CLE: Record "Cust. Ledger Entry");
    var
        DCLE: Record "Detailed Cust. Ledg. Entry";
        GLA: Record "G/L Account";
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        DCLE.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DCLE.SetRange("Cust. Ledger Entry No.", CLE."Entry No.");
        DCLE.SetFilter("Entry Type", '%1|%2|%3', DCLE."Entry Type"::"Payment Discount", DCLE."Entry Type"::"Payment Discount Tolerance",
                                DCLE."Entry Type"::"Payment Tolerance");
        DCLE.SetRange(Unapplied, false);
        if DCLE.FindFirst then begin
            Customer.Get(CLE."Customer No.");
            CustPostingGroup.Get(Customer."Customer Posting Group");
            CustPostingGroup.TestField("Payment Disc. Debit Acc.");
            CustPostingGroup.TestField("Payment Tolerance Debit Acc.");
        end;

        if DCLE.FindFirst then
            repeat

                case DCLE."Entry Type" of
                    DCLE."Entry Type"::"Payment Discount":
                        GLA.Get(CustPostingGroup."Payment Disc. Debit Acc.");
                    DCLE."Entry Type"::"Payment Discount Tolerance":
                        GLA.Get(CustPostingGroup."Payment Tolerance Debit Acc.");
                    DCLE."Entry Type"::"Payment Tolerance":
                        GLA.Get(CustPostingGroup."Payment Tolerance Debit Acc.");
                end;

                CGLE."From Balance G/L" := GLA."Income/Balance" = GLA."Income/Balance"::"Balance Sheet";
                CGLE."G/L Account No." := GLA."No.";
                CGLE."Document Type" := CGLE."Document Type"::"G/L Entry";
                CGLE."Document No." := CLE."Document No.";
                CGLE."Posting Date" := CLE."Posting Date";
                CGLE."Document Posting Date" := 0D;
                CGLE."Global Dimension 1 Code" := CLE."Global Dimension 1 Code";
                CGLE."Global Dimension 2 Code" := CLE."Global Dimension 2 Code";

                CGLE.Amount := -DCLE.Amount;
                CGLE."Payment No." := '';

                CGLE."GL Document Type" := CGLE."GL Document Type"::Payment;
                CGLE."Dimension Set ID" := CLE."Dimension Set ID";

                PostCashEntry(CGLE, true);
            until DCLE.Next = 0;
    end;

    procedure FindTaxEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Reverse: Boolean);
    var
        GLE: Record "G/L Entry";
        GLA: Record "G/L Account";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        // This function finds sales tax entries and post them. This is only required for Sales and Purchase documents via A/R and A/P and NOT for General journal postings
        //!SlgCash 2010 R2
        //Global CGLE values should already be set coming into this...
        GLE.SetCurrentKey("Document Type", "Document No.", "Posting Date", "SLGI CSH Tax Entry");
        GLE.SetRange("Document Type", DocumentType);
        GLE.SetRange("Document No.", DocumentNo);
        GLE.SetRange("SLGI CSH Tax Entry", true);
        GLE.SetFilter("Source Type", '<>%1', GLE."Source Type"::"Fixed Asset");

        if GLE.FindFirst then
            repeat
                GLA.Get(GLE."G/L Account No.");
                CGLE."From Balance G/L" := GLA."Income/Balance" = GLA."Income/Balance"::"Balance Sheet";
                CGLE."G/L Account No." := GLA."No.";
                CGLE."Document Type" := CGLE."Document Type"::"G/L Entry";
                CGLE."GL Document Type" := GLE."Document Type";
                CGLE.Amount := CalcCashAmount(GLE.Amount);
                // CGLE.Amount := GLE.Amount;
                if Reverse then
                    CGLE.Amount := -CGLE.Amount;
                PostCashEntry(CGLE, false);
            until GLE.Next = 0;
    end;

    local procedure CheckDimPostingRules(var SelectedDim: Record "Selected Dimension"): Text[1024];
    var
        DefaultDim: Record "Default Dimension";
        s: Text;
        d: Text;
        PrevAcc: Code[20];
    begin
        DefaultDim.SetRange("Table ID", Database::"G/L Account");
        DefaultDim.SetFilter(
          "Value Posting", '%1|%2',
          DefaultDim."Value Posting"::"Same Code", DefaultDim."Value Posting"::"Code Mandatory");

        if DefaultDim.Find('-') then
            repeat
                SelectedDim.SetRange("Dimension Code", DefaultDim."Dimension Code");
                if not SelectedDim.Find('-') then begin
                    if StrPos(d, DefaultDim."Dimension Code") < 1 then
                        d := d + ' ' + Format(DefaultDim."Dimension Code");
                    if PrevAcc <> DefaultDim."No." then begin
                        PrevAcc := DefaultDim."No.";
                        if s = '' then
                            s := Text020;
                        s := s + ' ' + Format(DefaultDim."No.");
                    end;
                end;
                SelectedDim.SetRange("Dimension Code");
            until (DefaultDim.Next = 0) or (StrLen(s) > MaxStrLen(s) - MaxStrLen(DefaultDim."No.") - StrLen(Text021) - 1);
        if s <> '' then
            s := CopyStr(s + Text021 + d, 1, MaxStrLen(s));
        exit(s);
    end;

    local procedure GetCBEntryDimensions(EntryNo: Integer; var DimBuf: Record "Dimension Buffer");
    var
        CBEntry: Record "SLGI Cash G/L Entry";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DimBuf.DeleteAll;
        CBEntry.Get(EntryNo);
        DimSetEntry.SetRange("Dimension Set ID", CBEntry."Dimension Set ID");
        if DimSetEntry.FindSet then
            repeat
                DimBuf."Table ID" := Database::"SLGI Cash G/L Entry";
                DimBuf."Entry No." := EntryNo;
                DimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                DimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                DimBuf.Insert;
            until DimSetEntry.Next = 0;
    end;

    local procedure CalcSumsInFilter();
    begin
        CGLE.CalcSums(Amount);
        TotalAmount := TotalAmount + CGLE.Amount;
    end;

    local procedure GetFAcqusitionAccount(FAcode: Code[20]): Code[20];
    var
        DepBook: Record "Depreciation Book";
        FAbook: Record "FA Depreciation Book";
        FAPostGr: Record "FA Posting Group";
    begin
        DepBook.SetRange("G/L Integration - Acq. Cost", true);
        DepBook.FindSet;
        FAbook.Get(FAcode, DepBook.Code);
        FAPostGr.Get(FAbook."FA Posting Group");
        exit(FAPostGr."Acquisition Cost Account");
    end;

    local procedure GetFAMaintenanceAccount(FAcode: Code[20]): Code[20];
    var
        DepBook: Record "Depreciation Book";
        FAbook: Record "FA Depreciation Book";
        FAPostGr: Record "FA Posting Group";
    begin
        DepBook.SetRange(DepBook."G/L Integration - Maintenance", true);
        DepBook.FindSet;
        FAbook.Get(FAcode, DepBook.Code);
        FAPostGr.Get(FAbook."FA Posting Group");
        exit(FAPostGr."Maintenance Expense Account");
    end;

    local procedure GetFAAppreciationAccount(FAcode: Code[20]): Code[20];
    var
        DepBook: Record "Depreciation Book";
        FAbook: Record "FA Depreciation Book";
        FAPostGr: Record "FA Posting Group";
    begin
        DepBook.SetRange(DepBook."G/L Integration - Appreciation", true);
        DepBook.FindSet;
        FAbook.Get(FAcode, DepBook.Code);
        FAPostGr.Get(FAbook."FA Posting Group");
        exit(FAPostGr."Appreciation Account");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishPreReport(TempSelectedDim: Record "Selected Dimension" temporary; var CashLedgerEntry: Record "SLGI Cash G/L Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCashEntry(GLAccount: Record "G/L Account"; GLEntry: Record "G/L Entry"; var CashLedgerEntry: Record "SLGI Cash G/L Entry")
    begin
    end;

    local procedure OnBeforePostCashEntryPurchaseInv(PIH: Record "Purch. Inv. Header"; PIL: Record "Purch. Inv. Line"; var CashLedgerEntry: Record "SLGI Cash G/L Entry")
    begin
    end;

    local procedure OnBeforePostCashEntryPurchaseCrM(PCH: Record "Purch. Cr. Memo Hdr."; PCL: Record "Purch. Cr. Memo Line"; var CashLedgerEntry: Record "SLGI Cash G/L Entry")
    begin
    end;

    local procedure OnBeforePostCashEntrySalesInv(SIH: Record "Sales Invoice Header"; SIL: Record "Sales Invoice Line"; var CashLedgerEntry: Record "SLGI Cash G/L Entry")
    begin
    end;

    local procedure OnBeforePostCashEntrySalesCrM(SCH: Record "Sales Cr.Memo Header"; SCL: Record "Sales Cr.Memo Line"; var CashLedgerEntry: Record "SLGI Cash G/L Entry")
    begin
    end;
}

