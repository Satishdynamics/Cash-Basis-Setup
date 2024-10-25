namespace CashBasisAccounting.CashBasisAccounting;

using Microsoft.Purchases.History;

pageextension 50063 "SLGI CSH Post Purch CrMemo" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addlast(General)
        {
            field("SLGI CSH Overide Cash App Date"; Rec."SLGI CSH Overide Cash App Date")
            {
                ApplicationArea = All;
                Visible = false;
                // ToolTip = 'Fill this field out if you like to use a set cash basis application date for this credit memo';
                // AssistEdit = true;
                // trigger OnAssistEdit()
                // var
                //     PurchApplication: Codeunit "SLGI CSH Purchase Application";
                // begin
                //     PurchApplication.PurchaseCrMemoApplication(Rec);
                // end;
            }
        }
    }
}