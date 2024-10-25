namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.GeneralLedger.Ledger;

pageextension 50057 "SLGI CSH General Ledger Ext" extends "General Ledger Entries"
{

    layout
    {
        addafter(Amount)
        {
            field("SLGI CSH Exclude In Cash"; Rec."SLGI CSH Exclude In Cash")
            {
                Caption = 'Exclude In Cash';
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // addlast("Ent&ry")
        // {
        //     action(ToggleTaxEntry)
        //     {
        //         Caption = 'Toggle Cash Tax Entry';
        //         Image = ToggleBreakpoint;
        //         ApplicationArea = All;
        //         trigger OnAction()
        //         var
        //             CashBasisMgmt: Codeunit "SLGI Cash Basis Mgmt";
        //         begin
        //             CashBasisMgmt.ToggleTaxEntry(Rec);
        //         end;
        //     }
        // }
    }
}


