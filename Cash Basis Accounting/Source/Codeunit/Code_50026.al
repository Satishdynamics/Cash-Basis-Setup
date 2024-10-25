codeunit 50051 "SLGI CSH Account Schedule"
{
    [EventSubscriber(ObjectType::Table, Database::"Column Layout Name", 'OnAfterValidateEvent', 'Analysis View Name', true, true)]
    local procedure OnValidateAnalysisViewName(var Rec: Record "Column Layout Name")
    var
        AnalysisView: Record "Analysis View";
    begin
        if AnalysisView.Get(Rec."Analysis View Name") then
            if AnalysisView."SLGI CSH Cash Basis" <> Rec."SLGI CSH Cash Basis" then
                Error('Analysis view %1 must match the cash basis field', Rec."Analysis View Name");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AccSchedManagement, 'OnBeforeCalcGLAcc', '', true, true)]

    local procedure OnBeforeCalcGL(var GLAcc: Record "G/L Account";
                                   var AccSchedLine: Record "Acc. Schedule Line";
                                   var ColumnLayout: Record "Column Layout";
                                   CalcAddCurr: Boolean;
                                   var ColValue: Decimal;
                                   var IsHandled: Boolean)

    var
        CashEntry: Record "SLGI Cash G/L Entry";
        AnalysisViewEntry: Record "Analysis View Entry";
        ColumnLayoutName: Record "Column Layout Name";
        AccScheduleName: Record "Acc. Schedule Name";
        AccSchedMgmt: Codeunit AccSchedManagement;
        AmountType: Enum "Account Schedule Amount Type";
        Balance: Decimal;
        TestBalance: Boolean;
        UseDimFilter: Boolean;
    begin
        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::"Budget Entries" then
            exit;
        ColumnLayoutName.Get(ColumnLayout."Column Layout Name");
        if not ColumnLayoutName."SLGI CSH Cash Basis" then
            exit;

        if CalcAddCurr then
            Error('Additional currency is not supported for cash basis');

        AccScheduleName.Get(AccSchedLine."Schedule Name");
        AmountType := ColumnLayout."Amount Type";
        TestBalance :=
            AccSchedLine.Show in [AccSchedLine.Show::"When Positive Balance", AccSchedLine.Show::"When Negative Balance"];
        UseDimFilter := AccSchedMgmt.HasDimFilter(AccSchedLine, ColumnLayout);
        if AccScheduleName."Analysis View Name" = '' then begin
            SetGLAccCashEntryFilters(GLAcc, CashEntry, AccSchedLine, ColumnLayout, UseDimFilter);
            case AmountType of
                AmountType::"Net Amount":
                    begin
                        CashEntry.CalcSums(Amount);
                        ColValue := CashEntry.Amount;
                        Balance := ColValue;
                    end;
                AmountType::"Debit Amount":
                    begin
                        if TestBalance then begin
                            CashEntry.CalcSums("Debit Amount", Amount);
                            Balance := CashEntry.Amount;
                        end else
                            CashEntry.CalcSums("Debit Amount");
                        ColValue := CashEntry."Debit Amount";
                    end;
                AmountType::"Credit Amount":
                    begin
                        if TestBalance then begin
                            CashEntry.CalcSums("Credit Amount", Amount);
                            Balance := CashEntry.Amount;
                        end else
                            CashEntry.CalcSums("Credit Amount");
                        ColValue := CashEntry."Credit Amount";
                    end;
            end;
        end else begin
            SetGLAccCashAnalysisViewEntryFilters(GLAcc, AnalysisViewEntry, AccScheduleName, AccSchedLine, ColumnLayout);
            case AmountType of
                AmountType::"Net Amount":
                    begin
                        AnalysisViewEntry.CalcSums(Amount);
                        ColValue := AnalysisViewEntry.Amount;
                        Balance := ColValue;
                    end;
                AmountType::"Debit Amount":
                    begin
                        if TestBalance then begin
                            AnalysisViewEntry.CalcSums("Debit Amount", Amount);
                            Balance := CashEntry.Amount;
                        end else
                            CashEntry.CalcSums("Debit Amount");
                        ColValue := AnalysisViewEntry."Debit Amount";
                    end;
                AmountType::"Credit Amount":
                    if CalcAddCurr then begin
                        if TestBalance then begin
                            AnalysisViewEntry.CalcSums("Credit Amount", Amount);
                            Balance := AnalysisViewEntry.Amount;
                        end else
                            AnalysisViewEntry.CalcSums("Credit Amount");
                        ColValue := AnalysisViewEntry."Credit Amount";
                    end;
            end;
            if TestBalance then begin
                if AccSchedLine.Show = AccSchedLine.Show::"When Positive Balance" then
                    if Balance < 0 then
                        ColValue := 0;
                if AccSchedLine.Show = AccSchedLine.Show::"When Negative Balance" then
                    if Balance > 0 then
                        ColValue := 0;
            end;
        end;
        IsHandled := true;
    end;

    local procedure SetGLAccCashEntryFilters(var GLAcc: Record "G/L Account";
                                             var CashEntry: Record "SLGI Cash G/L Entry";
                                             var AccSchedLine: Record "Acc. Schedule Line";

                                             var ColumnLayout: Record "Column Layout";
                                             UseDimFilter: Boolean)
    var
        AccSchedMgmt: Codeunit AccSchedManagement;
    begin
        if UseDimFilter then
            CashEntry.SetCurrentKey("G/L Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code")
        else
            CashEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        if GLAcc.Totaling = '' then
            CashEntry.SetRange("G/L Account No.", GLAcc."No.")
        else
            CashEntry.SetFilter("G/L Account No.", GLAcc.Totaling);
        GLAcc.CopyFilter("Date Filter", CashEntry."Posting Date");
        AccSchedLine.CopyFilter("Dimension 1 Filter", CashEntry."Global Dimension 1 Code");
        AccSchedLine.CopyFilter("Dimension 2 Filter", CashEntry."Global Dimension 2 Code");
        CashEntry.FilterGroup(2);
        CashEntry.SetFilter("Global Dimension 1 Code", AccSchedMgmt.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
        CashEntry.SetFilter("Global Dimension 2 Code", AccSchedMgmt.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
        CashEntry.FilterGroup(8);
        CashEntry.SetFilter("Global Dimension 1 Code", AccSchedMgmt.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"));
        CashEntry.SetFilter("Global Dimension 2 Code", AccSchedMgmt.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"));
        CashEntry.FilterGroup(0);
    end;

    local procedure SetGLAccCashAnalysisViewEntryFilters(var GLAcc: Record "G/L Account"; var AnalysisViewEntry: Record "Analysis View Entry"; AccSchedName: Record "Acc. Schedule Name"; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    var
        AccSchedMgmt: Codeunit AccSchedManagement;
    begin
        AnalysisViewEntry.SetRange("Analysis View Code", AccSchedName."Analysis View Name");
        AnalysisViewEntry.SetRange("Account Source", AnalysisViewEntry."Account Source"::"G/L Account");
        if GLAcc.Totaling = '' then
            AnalysisViewEntry.SetRange("Account No.", GLAcc."No.")
        else
            AnalysisViewEntry.SetFilter("Account No.", GLAcc.Totaling);
        GLAcc.CopyFilter("Date Filter", AnalysisViewEntry."Posting Date");
        AccSchedLine.CopyFilter("Business Unit Filter", AnalysisViewEntry."Business Unit Code");
        AnalysisViewEntry.CopyDimFilters(AccSchedLine);
        AnalysisViewEntry.FilterGroup(2);
        AnalysisViewEntry.SetDimFilters(
          AccSchedMgmt.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"),
          AccSchedMgmt.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"),
          AccSchedMgmt.GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"),
          AccSchedMgmt.GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"));
        AnalysisViewEntry.FilterGroup(8);
        AnalysisViewEntry.SetDimFilters(
          AccSchedMgmt.GetDimTotalingFilter(1, ColumnLayout."Dimension 1 Totaling"),
          AccSchedMgmt.GetDimTotalingFilter(2, ColumnLayout."Dimension 2 Totaling"),
          AccSchedMgmt.GetDimTotalingFilter(3, ColumnLayout."Dimension 3 Totaling"),
          AccSchedMgmt.GetDimTotalingFilter(4, ColumnLayout."Dimension 4 Totaling"));
        AnalysisViewEntry.FilterGroup(0);
    end;
}