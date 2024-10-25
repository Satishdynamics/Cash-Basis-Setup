pageextension 50050 "SLGI CSH Chart of Accounts Ext" extends "Chart of Accounts"
{
    layout
    {

        addafter("Net Change")
        {

            field("SLGI CSH Net Change Cash"; Rec."SLGI CSH Net Change Cash")
            {
                Caption = 'Net Change Cash';
                ApplicationArea = All;
                Editable = false;
            }

        }
        addafter("Balance at Date")
        {
            field("SLGI CSH Balance at Date Cash"; Rec."SLGI CSH Balance at Date Cash")
            {
                Caption = 'Balance at Date Cash';
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
    actions
    {
        addlast(processing)
        {
            action(SlgCCSHCalcCash)
            {
                Caption = 'Calculate Cash';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = report "SLGI CSH Calculate Cash Basis";
                ApplicationArea = All;
            }
            action(SlgCCSHCashAdjustmentJournal)
            {
                Caption = 'Cash Adjustment Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = page "SLGI Cash Adjustment Journal";
                ApplicationArea = All;
            }
        }
        addlast(reporting)
        {
            action(SlgCCSHTrialBalance1)
            {
                Caption = 'Cash Trial Balance';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Balance";
                ApplicationArea = All;
            }
            action(SlgCCSHTrialBalance2)
            {
                Caption = 'Cash Trial Balance, Details/Summary';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Bal Det Sum";
                ApplicationArea = All;
            }
            action(SlgCCSHTrialBalance3)
            {
                Caption = 'Cash Trial Balance Per Global Dims';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Bal GlobDim";
                ApplicationArea = All;
            }
            action(SlgCCSHTrialBalance4)
            {
                Caption = 'Cash Trial Balance Spread Global Dims';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash TrialBal Spread GDim";
                ApplicationArea = All;
            }
            action(SlgCCSHTrialBalance5)
            {
                Caption = 'Cash Trial Balance Spread Periods';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Balance Spread";
                ApplicationArea = All;
            }
            action(SlgCCSHExportCash)
            {
                Caption = 'Export Cash Ledger to CSV file';
                Image = Export;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI CSH Export Cash Ledger";
                ApplicationArea = All;
            }
        }
    }


}

