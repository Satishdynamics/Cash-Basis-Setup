codeunit 50057 "SLGI CSH AnaViewToCashEntries"
{

    trigger OnRun()
    begin
    end;

    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";

    procedure GetCashEntries(var AnalysisViewEntry: Record "Analysis View Entry"; var TempCashEntry: Record "SLGI Cash G/L Entry")
    var
        CashEntry: Record "SLGI Cash G/L Entry";
        AnalysisViewFilter: Record "Analysis View Filter";
        UpdateAnalysisView: Codeunit "SLGI CSH Update Analysis View";
        StartDate: Date;
        EndDate: Date;
        GlobalDimValue: Code[20];
    begin
        AnalysisView.Get(AnalysisViewEntry."Analysis View Code");

        if AnalysisView."Date Compression" = AnalysisView."Date Compression"::None then begin
            if CashEntry.Get(AnalysisViewEntry."Entry No.") then begin
                TempCashEntry := CashEntry;
                TempCashEntry.Insert();
            end;
            exit;
        end;

        GLSetup.Get();

        StartDate := AnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        if StartDate < AnalysisView."Starting Date" then
            StartDate := 0D
        else
            if (AnalysisViewEntry."Posting Date" = NormalDate(AnalysisViewEntry."Posting Date")) and
               not (AnalysisView."Date Compression" in [AnalysisView."Date Compression"::None, AnalysisView."Date Compression"::Day])
            then
                EndDate := CalculateEndDate(AnalysisView."Date Compression", AnalysisViewEntry);

        CashEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        CashEntry.SetRange("G/L Account No.", AnalysisViewEntry."Account No.");
        CashEntry.SetRange("Posting Date", StartDate, EndDate);
        CashEntry.SetRange("Entry No.", 0, AnalysisView."Last Entry No.");

        if GetGlobalDimValue(GLSetup."Global Dimension 1 Code", AnalysisViewEntry, GlobalDimValue) then
            CashEntry.SetRange("Global Dimension 1 Code", GlobalDimValue)
        else
            if AnalysisViewFilter.Get(AnalysisViewEntry."Analysis View Code", GLSetup."Global Dimension 1 Code")
            then
                CashEntry.SetFilter("Global Dimension 1 Code", AnalysisViewFilter."Dimension Value Filter");

        if GetGlobalDimValue(GLSetup."Global Dimension 2 Code", AnalysisViewEntry, GlobalDimValue) then
            CashEntry.SetRange("Global Dimension 2 Code", GlobalDimValue)
        else
            if AnalysisViewFilter.Get(AnalysisViewEntry."Analysis View Code", GLSetup."Global Dimension 2 Code")
            then
                CashEntry.SetFilter("Global Dimension 2 Code", AnalysisViewFilter."Dimension Value Filter");

        if CashEntry.Find('-') then
            repeat
                if DimEntryOK(CashEntry."Dimension Set ID", AnalysisView."Dimension 1 Code", AnalysisViewEntry."Dimension 1 Value Code") and
                   DimEntryOK(CashEntry."Dimension Set ID", AnalysisView."Dimension 2 Code", AnalysisViewEntry."Dimension 2 Value Code") and
                   DimEntryOK(CashEntry."Dimension Set ID", AnalysisView."Dimension 3 Code", AnalysisViewEntry."Dimension 3 Value Code") and
                   DimEntryOK(CashEntry."Dimension Set ID", AnalysisView."Dimension 4 Code", AnalysisViewEntry."Dimension 4 Value Code") and
                   UpdateAnalysisView.DimSetIDInFilter(CashEntry."Dimension Set ID", AnalysisView)
                then begin
                    TempCashEntry := CashEntry;
                    if TempCashEntry.Insert() then;
                end;
            until CashEntry.Next() = 0;
    end;

    procedure DimEntryOK(DimSetID: Integer; Dim: Code[20]; DimValue: Code[20]): Boolean
    begin
        if Dim = '' then
            exit(true);

        if DimSetEntry.Get(DimSetID, Dim) then
            exit(DimSetEntry."Dimension Value Code" = DimValue);

        exit(DimValue = '');
    end;

    local procedure CalculateEndDate(DateCompression: Integer; AnalysisViewEntry: Record "Analysis View Entry"): Date
    var
        AnalysisView2: Record "Analysis View";
        AccountingPeriod: Record "Accounting Period";
    begin
        case DateCompression of
            AnalysisView2."Date Compression"::Week:
                exit(CalcDate('<+6D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Month:
                exit(CalcDate('<+1M-1D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Quarter:
                exit(CalcDate('<+3M-1D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Year:
                exit(CalcDate('<+1Y-1D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Period:
                begin
                    AccountingPeriod."Starting Date" := AnalysisViewEntry."Posting Date";
                    if AccountingPeriod.Next() <> 0 then
                        exit(CalcDate('<-1D>', AccountingPeriod."Starting Date"));

                    exit(DMY2Date(31, 12, 9999));
                end;
        end;
    end;

    procedure GetGlobalDimValue(GlobalDim: Code[20]; var AnalysisViewEntry: Record "Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            AnalysisView."Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 1 Value Code";
                end;
            AnalysisView."Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 2 Value Code";
                end;
            AnalysisView."Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 3 Value Code";
                end;
            AnalysisView."Dimension 4 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 4 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;
}

