
codeunit 50056 "SLGI CSH Analys View Event Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update Analysis View", 'OnBeforeUpdateOne', '', true, true)]
    local procedure OnBeforeUpdateOne(var NewAnalysisView: Record "Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; ShowWindow: Boolean; var IsHandled: Boolean)
    var
        UpdateCashBasisAnalysisView: Codeunit "SLGI CSH Update Analysis View";
    begin
        if NewAnalysisView."SLGI CSH Cash Basis" then begin
            UpdateCashBasisAnalysisView.Run(NewAnalysisView);
            IsHandled := true;
        end
    end;

    [EventSubscriber(ObjectType::Table, Database::"Analysis View", 'OnAfterValidateEvent', 'Account Source', true, true)]
    local procedure OnAfterValidateAccountSource(Rec: Record "Analysis View")
    begin
        if Rec."SLGI CSH Cash Basis" and (Rec."Account Source" = Rec."Account Source"::"Cash Flow Account") then
            Error('Cash basis does not support Cash Flow Accounts');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Analysis View Entry", 'OnBeforeDrilldown', '', true, true)]
    local procedure OnBeforeDrillDownAMount(AnalysisViewEntry: Record "Analysis View Entry"; var IsHandled: Boolean)
    var
        TempCashEntry: Record "SLGI Cash G/L Entry" temporary;
        AnalysisView: Record "Analysis View";
        AnalysisViewEntryToCashEntries: Codeunit "SLGI CSH AnaViewToCashEntries";
    begin
        AnalysisView.Get(AnalysisViewEntry."Analysis View Code");
        if not AnalysisView."SLGI CSH Cash Basis" then
            exit;

        if AnalysisViewEntry."Account Source" = AnalysisViewEntry."Account Source"::"G/L Account" then begin
            TempCashEntry.Reset();
            TempCashEntry.DeleteAll();
            AnalysisViewEntryToCashEntries.GetCashEntries(AnalysisViewEntry, TempCashEntry);
            Page.RunModal(Page::"SLGI Cash G/L Entries", TempCashEntry);
        end else
            Error('Cash Basis does not support Cash Flow Accounts');
        IsHandled := true;
    end;
}
