pageextension 50051 "SLGI CSH Accounting Periods" extends "Accounting Periods"
{

    layout
    {
        addafter("New Fiscal Year")
        {
            field("SLGI CSH New Cash Fiscal Year"; Rec."SLGI CSH New Cash Fiscal Year")
            {
                ApplicationArea = All;
                Caption = 'New Cash Year';
            }
            field("SLGI CSH Cash Closed"; Rec."SLGI CSH Cash Closed")
            {
                ApplicationArea = All;
                Caption = 'Cash Closed';
            }
        }
    }

    actions
    {
        addafter("C&lose Year")
        {
            action(SlgCCSH_CashCreateYear)
            {
                Caption = 'Cash Create year';
                ApplicationArea = All;
                Image = CreateYear;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = report "SLGI CSH Create Cash Year";
            }
            action(SlgCCSH_CashCloseYear)
            {
                Caption = 'Cash Close year';
                ApplicationArea = All;
                Image = CloseYear;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SlgCCashMgmt: Codeunit "SLGI Cash Basis Mgmt";
                begin
                    SlgCCashMgmt.RunCashClose(Rec);
                end;
            }
        }
    }
}

