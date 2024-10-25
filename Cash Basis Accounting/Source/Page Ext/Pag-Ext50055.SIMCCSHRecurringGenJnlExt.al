namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.GeneralLedger.Journal;

pageextension 50055 "SLGI CSH Recurring Gen Jnl Ext" extends "Recurring General Journal"
{

    layout
    {
        addafter(Amount)
        {
            field("SLGI CSH Exclude In Cash"; Rec."SLGI CSH Exclude In Cash")
            {
                Caption = 'Exclude In Cash';
                ApplicationArea = All;
                Editable = SlgCCSHExcludeCashEditable;
            }
        }
    }
    trigger OnOpenPage()
    var
        SlgCCSHSetup: Record "SLGI Cash Basis Setup";
    begin
        SlgCCSHSetup.Get();
        SlgCCSHExcludeCashEditable := SlgCCSHSetup."Allow Exclude Cash Editable";
    end;

    var
        SlgCCSHExcludeCashEditable: Boolean;
}

