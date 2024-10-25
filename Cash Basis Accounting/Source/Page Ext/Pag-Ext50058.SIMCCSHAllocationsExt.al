namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Finance.GeneralLedger.Journal;

pageextension 50058 "SLGI CSH Allocations Ext" extends Allocations // 284
{
    layout
    {
        addafter("Allocation %")
        {
            field("SLGI CSH Exclude in Cash"; Rec."SLGI CSH Exclude in Cash")
            {
                ApplicationArea = All;
                Caption = 'Exclude in Cash';
            }
        }
    }

}