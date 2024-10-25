codeunit 50052 "SLGI Cash Basis Event Subs"
{

    Permissions = tabledata 25 = m,
                  tabledata 17 = M;

    var
        SalesDocDeleteErrorLbl: Label 'Cash Basis does not allow deletion of posted documents!';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLEntry', '', false, false)]
    local procedure OnAfterInitGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."SLGI CSH Exclude In Cash" := GenJournalLine."SLGI CSH Exclude In Cash";
        GLEntry."SLGI CSH Tax Entry" := GenJournalLine."SLGI CSH Tax Entry";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeProcessLines', '', false, false)]
    local procedure OnBeforeProcessGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    var
        CashSetup: Record "SLGI Cash Basis Setup";
        CashErrorTxt: Label 'Line %1 error: Document Type can''t be blank. This is a cash basis requirement.';
        CashError2Txt: Label 'Line %1 error: Customer and Vendor entries can not be excluded from cash. This is a cash basis requirement.';
    begin
        CashSetup.Get();
        if GenJournalLine.FindFirst() then
            repeat
                if (((GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type"::Customer]) or
                       (GenJournalLine."Bal. Account Type" in [GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type"::Customer])) and
                    (GenJournalLine."Document Type" = GenJournalLine."Document Type"::" ")) then
                    Error(CashErrorTxt, GenJournalLine."Line No.");

                if (((GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type"::Customer]) or
                                       (GenJournalLine."Bal. Account Type" in [GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type"::Customer])) and
                                    (GenJournalLine."SLGI CSH Exclude In Cash")) then
                    Error(CashError2Txt, GenJournalLine."Line No.");
            until GenJournalLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterValidateEvent', 'Type', false, false)]
    local procedure OnAfterSalesLineType(Rec: Record "Sales Line")
    begin
        if Rec.Type = Rec.Type::"Fixed Asset" then
            Error('Cash Basis does not allow Fixed Assets using a Sales Document. Use a Fixed Asset General Journal instead.');
    end;

    [EventSubscriber(ObjectType::Table, 39, 'OnBeforeValidateEvent', 'Use Tax', false, false)]
    local procedure CheckUseTaxOnPurchase(var Rec: Record "Purchase Line");
    var
        UseTaxErrorTxt: Label 'Use Tax is not supported for Cash Basis. Manual adjustments may be needed afterwards.';
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Use Tax" then
            Message(UseTaxErrorTxt);
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterGenJnlLineInsert(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean);
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if Rec.IsTemporary() or not RunTrigger or Rec."SLGI CSH Exclude In Cash" then
            exit;
        GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        Rec."SLGI CSH Exclude In Cash" := GenJnlBatch."SLGI CSH Exclude In Cash";
        Rec.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromGenJnlAllocation', '', false, false)]
    local procedure CopyFromGenJnlAlloc(GenJnlAllocation: Record "Gen. Jnl. Allocation"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."SLGI CSH Exclude In Cash" := GenJnlAllocation."SLGI CSH Exclude in Cash";
    end;

    [EventSubscriber(ObjectType::Table, 112, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteSIH(var Rec: Record "Sales Invoice Header"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        Error(SalesDocDeleteErrorLbl);
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteSCH(var Rec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        Error(SalesDocDeleteErrorLbl);
    end;

    [EventSubscriber(ObjectType::Table, 122, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeletePIH(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        Error(SalesDocDeleteErrorLbl);
    end;

    [EventSubscriber(ObjectType::Table, 124, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeletePCH(var Rec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        Error(SalesDocDeleteErrorLbl);
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesTaxToGL', '', false, false)]
    // local procedure OnBeforePostSalesTaxToGLSales(var GenJnlLine: Record "Gen. Journal Line");
    // var
    //     SourceCodeSetup: Record "Source Code Setup";
    // begin
    //     SourceCodeSetup.Get();
    //     if (GenJnlLine."Source Code" <> SourceCodeSetup."Fixed Asset G/L Journal") and (GenJnlLine."Source Type" <> GenJnlLine."Source Type"::"Fixed Asset") then
    //         GenJnlLine."SLGI CSH Tax Entry" := true;
    // end;//SATISH

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitVAT', '', true, true)]
    local procedure OnAfterInitVAT(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if (GenJournalLine."Source Code" <> SourceCodeSetup."Fixed Asset G/L Journal") and (GenJournalLine."Source Type" <> GenJournalLine."Source Type"::"Fixed Asset") then
            GenJournalLine."SLGI CSH Tax Entry" := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 226, 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry");
    var
        EntriesToApply: Record "Cust. Ledger Entry";
        SlgCash001Lbl: Label 'Cash Basis does not allow two of the same document types applied to each other!\Please remove %1 %2 from the applies-to list or try changing the Applying Entry.';
    begin
        // EntriesToApply.SetCurrentKey("Customer No.", "Applies-to ID");
        // EntriesToApply.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        // EntriesToApply.SetRange("Applies-to ID", CustLedgerEntry."Applies-to ID");
        // EntriesToApply.SetRange("Document Type", CustLedgerEntry."Document Type"); //Look for same doc type...
        // EntriesToApply.SetFilter("Entry No.", '<>%1', CustLedgerEntry."Entry No.");
        // if EntriesToApply.FindSet() then
        //     Error(SlgCash001Lbl, EntriesToApply."Document Type", EntriesToApply."Document No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 227, 'OnBeforePostApplyVendLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry");
    var
        EntriesToApply: Record "Vendor Ledger Entry";
        SlgCash001Lbl: Label 'Cash Basis does not allow two of the same document types applied to each other!\Please remove %1 %2 from the applies-to list or try changing the Applying Entry.';
    begin
        EntriesToApply.SetCurrentKey("Vendor No.", "Applies-to ID");
        EntriesToApply.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        EntriesToApply.SetRange("Applies-to ID", VendorLedgerEntry."Applies-to ID");
        EntriesToApply.SetRange("Document Type", VendorLedgerEntry."Document Type"); //Look for same doc type...
        EntriesToApply.SetFilter("Entry No.", '<>%1', VendorLedgerEntry."Entry No.");
        if EntriesToApply.FindSet() then
            Error(SlgCash001Lbl, EntriesToApply."Document Type", EntriesToApply."Document No.");
    end;
}

