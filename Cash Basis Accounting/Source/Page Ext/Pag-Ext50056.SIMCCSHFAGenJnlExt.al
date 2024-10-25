namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.FixedAssets.Journal;

pageextension 50056 "SLGI CSH FA Gen Jnl Ext" extends "Fixed Asset G/L Journal"
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


