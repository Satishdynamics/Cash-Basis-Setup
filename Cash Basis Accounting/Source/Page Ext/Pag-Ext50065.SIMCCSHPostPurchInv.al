namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Purchases.History;

pageextension 50065 "SLGI CSH Post Purch Inv" extends "Posted Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            field("SLGI CSH Overide Cash App Date"; Rec."SLGI CSH Overide Cash App Date")
            {
                ApplicationArea = All;
                Visible = false;
                // ToolTip = 'Fill this field out if you like to use a set cash basis application date for this invoice';
                // AssistEdit = true;
                // trigger OnAssistEdit()
                // var
                //     PurchApplication: Codeunit "SLGI CSH Purchase Application";
                // begin
                //     PurchApplication.PurchaseInvoiceApplication(Rec);
                // end;
            }
        }
    }
}
