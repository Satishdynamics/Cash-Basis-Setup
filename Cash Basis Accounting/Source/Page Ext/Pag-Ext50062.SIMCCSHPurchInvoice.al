namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Purchases.Document;

pageextension 50062 "SLGI CSH Purch Invoice" extends "Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            field("SLGI CSH Overide Cash App Date"; Rec."SLGI CSH Overide Cash App Date")
            {
                ApplicationArea = All;
                Visible = false;
                ToolTip = 'Fill this field out if you like to use a set cash basis application date for this invoice';
            }
        }
    }
}
