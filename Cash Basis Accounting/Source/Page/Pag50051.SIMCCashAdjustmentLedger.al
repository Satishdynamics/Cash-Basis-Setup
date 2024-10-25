page 50051 "SLGI Cash Adjustment Ledger"
{
    Caption = 'Cash Basis Adjustment Ledger Entries';
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "SLGI Cash Adjust. Ledger Entry";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }


    actions
    {
        area(Navigation)
        {
            action(Dimensions)
            {
                Caption = 'Dimensions';
                Image = Dimensions;
                Promoted = true;
                PromotedCategory = Process;
                ShortcutKey = 'Shift+Ctrl+D';
                ApplicationArea = All;

                trigger OnAction();
                begin
                    Rec.ShowDimensions();
                end;
            }
            action("Cash Adjustment Journal")
            {
                Caption = 'Cash Adjustment Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = page "SLGI Cash Adjustment Journal";
                ApplicationArea = All;
            }
            action("Cash G/L Ledger")
            {
                Caption = 'Cash G/L Ledger';
                Image = LedgerEntries;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = page "SLGI Cash G/L Entries";
                ApplicationArea = All;
            }
        }
        area(Processing)
        {
            action(CalcCash)
            {
                Caption = 'Calculate Cash';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = report "SLGI CSH Calculate Cash Basis";
                ApplicationArea = All;
            }
        }
        area(Reporting)
        {
            action(TrialBalance1)
            {
                Caption = 'Cash Trial Balance';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Balance";
                ApplicationArea = All;
            }
            action(TrialBalance2)
            {
                Caption = 'Cash Trial Balance, Details/Summary';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Bal Det Sum";
                ApplicationArea = All;
            }
            action(TrialBalance3)
            {
                Caption = 'Cash Trial Balance Per Global Dims';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Bal GlobDim";
                ApplicationArea = All;
            }
            action(TrialBalance4)
            {
                Caption = 'Cash Trial Balance Spread Global Dims';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash TrialBal Spread GDim";
                ApplicationArea = All;
            }
            action(TrialBalance5)
            {
                Caption = 'Cash Trial Balance Spread Periods';
                Image = Report;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                RunObject = report "SLGI Cash Trial Balance Spread";
                ApplicationArea = All;
            }
        }
    }
}

