codeunit 50050 "SLGI Cash Basis Mgmt"
{
    Permissions = tabledata 50050 = rmid,
                    tabledata 50051 = rmi,
                    tabledata 50052 = rmi,
                    tabledata 50053 = rmi,
                    tabledata 50054 = rmi,
                    tabledata "G/L Entry" = M;


    var
        NoSeriesBatch: array[10] of Codeunit "No. Series - Batch";
        Text025Lbl: Label 'A maximum of %1 posting number series can be used in each journal.';
        Text102Lbl: Label 'Do you want to post the journal lines?';
        Text103Lbl: Label 'G/L Account %1 is blocked';
        Text104Lbl: Label 'Journal posted';
        Text105Lbl: Label 'Nothing to post';
        JnlNoZeroBalErrorLbl: Label 'Journal must have a zero balance';
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        SLP: Page 42;

    procedure ToggleTaxEntry(var GLE: Record "G/L Entry")
    begin
        if Confirm('Toggle Tax Entry?') then begin
            GLE."SLGI CSH Tax Entry" := not GLE."SLGI CSH Tax Entry";
            GLE.Modify();
        end;
    end;

    procedure RunCashClose(var AccPeriodRec: Record "Accounting Period")
    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriod2: Record "Accounting Period";
        AccountingPeriod3: Record "Accounting Period";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        CashText1Lbl: Label 'You must create a new Cash fiscal year before you can close the old year.';
        CashText2Lbl: Label 'This function closes the Cash fiscal year from %1 to %2.';
        CashText3Lbl: Label 'Once the Cash fiscal year is closed it cannot be opened again, and the periods in the fiscal year cannot be changed.\\';
        CashText4Lbl: Label 'Do you want to close the Cash fiscal year?';
    begin
        AccountingPeriod.Copy(AccPeriodRec);
        AccountingPeriod2.SetRange("SLGI CSH Cash Closed", false);
        AccountingPeriod2.Find('-');
        if not AccountingPeriod2."SLGI CSH New Cash Fiscal Year" then
            repeat
            until (AccountingPeriod2.Next() = 0) or AccountingPeriod2."SLGI CSH New Cash Fiscal Year";

        FiscalYearStartDate := AccountingPeriod2."Starting Date";
        AccountingPeriod := AccountingPeriod2;
        AccountingPeriod.TestField("SLGI CSH New Cash Fiscal Year", true);

        AccountingPeriod2.SetRange("SLGI CSH New Cash Fiscal Year", true);
        if AccountingPeriod2.Find('>') then begin
            FiscalYearEndDate := CalcDate('<-1D>', AccountingPeriod2."Starting Date");

            AccountingPeriod3 := AccountingPeriod2;
            AccountingPeriod2.SetRange("SLGI CSH New Cash Fiscal Year");
            AccountingPeriod2.Find('<');
        end else
            Error(CashText1Lbl);

        if not
          Confirm(
            CashText2Lbl +
            CashText3Lbl +
            CashText4Lbl, false,
            FiscalYearStartDate, FiscalYearEndDate)
        then
            exit;

        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, AccountingPeriod2."Starting Date");
        AccountingPeriod.ModifyAll("SLGI CSH Cash Closed", true);
        AccountingPeriod.Reset();
        AccPeriodRec := AccountingPeriod;
    end;

    procedure PostAdjustmentJournal(CashAdjJnlLn: Record "SLGI Cash Adjust. Journal Line");
    var
        CALE: Record "SLGI Cash Adjust. Ledger Entry";
        CAJ: Record "SLGI Cash Adjust. Journal Line";
        CAJ2: Record "SLGI Cash Adjust. Journal Line";
        GLA: Record "G/L Account";
        CAJB: Record "SLGI Cash Adjust. Jnl Batch";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        NextEntryNo: Integer;
        I: Integer;
    begin
        //Check total balance is 0
        CAJB.Get(CashAdjJnlLn."Journal Batch Name");
        if not CAJB."Allow Jnl. out of Balance" then begin
            CAJ2.SetRange("Journal Batch Name", CashAdjJnlLn."Journal Batch Name");
            CAJ2.CalcSums(CAJ2.Amount);
            if CAJ2.Amount <> 0 then
                Error(JnlNoZeroBalErrorLbl);
        end;

        if not Confirm(Text102Lbl)
          then
            exit;

        CALE.LockTable();
        if CALE.FindLast() then
            NextEntryNo += CALE."Entry No." + 1
        else
            NextEntryNo := 1;

        LastDocNo := '';
        CAJ.SetRange("Journal Batch Name", CashAdjJnlLn."Journal Batch Name");
        if CAJ.FindSet() then
            repeat
                if (CAJ."G/L Account No." <> '') or (CAJ.Amount <> 0) then begin
                    GLA.Get(CAJ."G/L Account No.");
                    if GLA.Blocked then
                        Error(Text103Lbl, GLA."No.");
                    GLA.TestField("Account Type", GLA."Account Type"::Posting);
                    CAJ.TestField("Posting Date");
                    CAJ.TestField("Document No.");
                    CAJ.TestField(Amount);
                    CAJ.TestField("G/L Account No.");

                    if LastDocNo <> CAJ."Document No." then begin
                        CAJ.CheckDocNoBasedOnNoSeries(LastDocNo, CAJB."No. Series", NoSeriesBatch);
                        NoSeriesBatch.SaveState();
                        LastDocNo := CAJ."Document No.";
                    end;

                    CALE.TransferFields(CAJ);
                    CALE."Entry No." := NextEntryNo;
                    CALE."User ID" := CopyStr(UserId(), 1, 50);
                    CALE.Insert();
                    I += 1;
                    NextEntryNo += 1;
                end;
            until CAJ.Next() = 0;
        CAJ.DeleteAll();


        if I > 0 then
            Message(Text104Lbl)
        else
            Message(Text105Lbl);
    end;

    procedure CheckDocumentNo(var CAJL2: Record "SLGI Cash Adjust. Journal Line");
    var
        CashJnlBatch: Record "SLGI Cash Adjust. Jnl Batch";
        NoSeries: Record "No. Series";
        NoOfPostingNoSeries: Integer;
    begin
        CashJnlBatch.Get(CAJL2."Journal Batch Name");
        if CAJL2."Posting No. Series" = '' then
            CAJL2."Posting No. Series" := CashJnlBatch."No. Series"
        else
            if not CAJL2.EmptyLine() then
                if CAJL2."Document No." = LastDocNo then
                    CAJL2."Document No." := LastPostedDocNo
                else begin
                    if not NoSeries.Get(CAJL2."Posting No. Series") then begin
                        NoOfPostingNoSeries += 1;
                        if NoOfPostingNoSeries > ArrayLen(NoSeriesBatch) then
                            Error(
                              Text025Lbl,
                              ArrayLen(NoSeriesBatch));
                        NoSeries.Code := CAJL2."Posting No. Series";
                        NoSeries.Description := Format(NoOfPostingNoSeries);
                        NoSeries.Insert();
                    end;
                    LastDocNo := CAJL2."Document No.";
                    CAJL2."Document No." :=
                      NoSeriesBatch[NoOfPostingNoSeries].GetNextNo(CAJL2."Posting No. Series", CAJL2."Posting Date", true);
                    LastPostedDocNo := CAJL2."Document No.";
                end;
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var CashJnlLine: Record "SLGI Cash Adjust. Journal Line");
    var
        CAJB: Record "SLGI Cash Adjust. Jnl Batch";
    begin
        if not CAJB.FindSet() then begin
            CAJB.Name := 'GENERAL';
            CAJB.Description := 'General Batch';
            CAJB.Insert();
            CurrentJnlBatchName := CAJB.Name;
        end;
        CashJnlLine.FilterGroup := 2;
        CashJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        CashJnlLine.FilterGroup := 0;
    end;

    procedure GetAccounts(var CashJnlLine: Record "SLGI Cash Adjust. Journal Line"; var AccName: Text[100]);
    var
        GLAcc: Record "G/L Account";
    begin
        AccName := '';
        if GLAcc.Get(CashJnlLine."G/L Account No.") then
            AccName := GLAcc.Name;
    end;

    procedure CalcBalance(var CashJnlLine: Record "SLGI Cash Adjust. Journal Line"; LastCashJnlLine: Record "SLGI Cash Adjust. Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean);
    var
        TempCashJnlLine: Record "SLGI Cash Adjust. Journal Line";
    begin
        TempCashJnlLine.CopyFilters(CashJnlLine);
        ShowTotalBalance := TempCashJnlLine.CalcSums("Balance (LCY)");
        if ShowTotalBalance then begin
            TotalBalance := TempCashJnlLine."Balance (LCY)";
            if CashJnlLine."Line No." = 0 then
                TotalBalance := TotalBalance + LastCashJnlLine."Balance (LCY)";
        end;

        if CashJnlLine."Line No." <> 0 then begin
            TempCashJnlLine.SetRange("Line No.", 0, CashJnlLine."Line No.");
            ShowBalance := TempCashJnlLine.CalcSums("Balance (LCY)");
            if ShowBalance then
                Balance := TempCashJnlLine."Balance (LCY)";
        end else begin
            TempCashJnlLine.SetRange("Line No.", 0, LastCashJnlLine."Line No.");
            ShowBalance := TempCashJnlLine.CalcSums("Balance (LCY)");
            if ShowBalance then begin
                Balance := TempCashJnlLine."Balance (LCY)";
                TempCashJnlLine.CopyFilters(CashJnlLine);
                TempCashJnlLine := LastCashJnlLine;
                if TempCashJnlLine.Next() = 0 then
                    Balance := Balance + LastCashJnlLine."Balance (LCY)";
            end;
        end;
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var CashJnlLine: Record "SLGI Cash Adjust. Journal Line");
    begin
        CashJnlLine.FilterGroup := 2;
        CashJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        CashJnlLine.FilterGroup := 0;
        if CashJnlLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var CashJnlLine: Record "SLGI Cash Adjust. Journal Line");
    var
        CashJnlBatch: Record "SLGI Cash Adjust. Jnl Batch";
    begin
        Commit();
        CashJnlBatch.Name := CashJnlLine.GetRangeMax("Journal Batch Name");
        if Page.RunModal(0, CashJnlBatch) = Action::LookupOK then begin
            CurrentJnlBatchName := CashJnlBatch.Name;
            SetName(CurrentJnlBatchName, CashJnlLine);
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var CashJnlLine: Record "SLGI Cash Adjust. Journal Line");
    var
        CashJnlBatch: Record "SLGI Cash Adjust. Jnl Batch";
    begin
        CashJnlBatch.Get(CurrentJnlBatchName);
    end;
}

