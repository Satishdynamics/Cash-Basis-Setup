namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.Analysis;

pageextension 50054 "SLGI CSH Chart Of Acc G/L Ext" extends "Chart of Accounts (G/L)"
{
    Caption = 'Chart of Accounts (G/L)';

    layout
    {

        addafter("Net Change")
        {

            field("SLGI CSH Net Change Cash"; Rec."SLGI CSH Net Change Cash")
            {
                Caption = 'Net Change Cash';
                ApplicationArea = All;
                Editable = false;
            }

        }
        addafter("Balance at Date")
        {
            field("SLGI CSH Balance at Date Cash"; Rec."SLGI CSH Balance at Date Cash")
            {
                Caption = 'Balance at Date Cash';
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
    actions
    {
        addfirst(processing)
        {
            action("SLGI CSH Cash Ledger Entries")
            {
                Image = LedgerEntries;
                ApplicationArea = All;
                Caption = 'Cash Ledger Entries';
                RunObject = page "SLGI Cash G/L Entries";
                RunPageLink = "G/L Account No." = field("No.");
                RunPageView = sorting("G/L Account No.", "Posting Date");
            }
            action("SLGI CSH Calculate Cash")
            {
                ApplicationArea = All;
                Caption = 'Calculate Cash';
                Image = CashFlow;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = codeunit "SLGI Cash Basis Mgmt";
                ShortcutKey = 'F11';
            }
        }
    }
}

