namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.FinancialReports;

pageextension 50059 "SLGI CSH Column Layout Names" extends "Column Layout Names"
{
    layout
    {
        addafter(Description)
        {
            field("SLGI CSH Cash Basis"; Rec."SLGI CSH Cash Basis")
            {
                ApplicationArea = All;
                ToolTip = 'Check this box to use cash ledger instead of accrual ledger';
            }
        }
    }

    actions
    {
    }
}