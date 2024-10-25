namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.Analysis;

pageextension 50060 "SLGI CSH Analysis Card" extends "Analysis View Card"
{
    layout
    {
        addafter("Account Source")
        {
            field("SLGI CSH Cash Basis"; Rec."SLGI CSH Cash Basis")
            {
                ApplicationArea = All;
                ToolTip = 'If checked, analysis view will use cash ledger instead of general ledger as its source of data';
            }
        }
        addafter("Update on Posting")
        {
            field("SLGI CSH Update on Cash Calc"; Rec."SLGI CSH Update on Cash Calc")
            {
                ApplicationArea = All;
                ToolTip = 'Indicates if analysis view is updated on calculation of cash';
            }
        }
    }
}