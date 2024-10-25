page 50053 "SLGI Cash Adjust Jnl Batches"
{
    Caption = 'Cash Basis Adjustment Journal Batches';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "SLGI Cash Adjust. Jnl Batch";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = All;
                }
                field("Allow Jnl. out of Balance"; Rec."Allow Jnl. out of Balance")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditJournal)
            {
                ApplicationArea = All;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortcutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                var
                    CashJnlLine: Record "SLGI Cash Adjust. Journal Line";
                begin
                    CashJnlLine."Journal Batch Name" := Rec.Name;
                    Page.Run(Page::"SLGI Cash Adjustment Journal", CashJnlLine);
                end;
            }
        }
    }
}

