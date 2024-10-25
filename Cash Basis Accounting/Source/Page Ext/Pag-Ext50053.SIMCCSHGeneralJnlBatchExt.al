namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.GeneralLedger.Journal;

pageextension 50053 "SLGI CSH General Jnl Batch Ext" extends "General Journal Batches"
{
    layout
    {
        addafter(Description)
        {
            field("SLGI CSH Exclude In Cash"; Rec."SLGI CSH Exclude In Cash")
            {
                Caption = 'Exclude In Cash';
                ApplicationArea = All;
            }
        }
    }
    //Unsupported feature: InsertAfter on "Documentation". Please convert manually.
}

