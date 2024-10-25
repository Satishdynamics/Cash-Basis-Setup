namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.Analysis;

pageextension 50061 "SLGI CSH Analysis List" extends "Analysis View List"
{
    layout
    {
        addafter("Account Source")
        {
            field("SLGI CSH Cash Basis"; Rec."SLGI CSH Cash Basis")
            {
                ApplicationArea = All;
            }
        }
    }
}
