page 50052 "SLGI Cash Adjustment Journal"
{
    Caption = 'Cash Basis Adjustment Journal';
    AutoSplitKey = true;
    DelayedInsert = true;
    PageType = Worksheet;
    UsageCategory = Lists;
    ApplicationArea = All;
    SaveValues = true;
    SourceTable = "SLGI Cash Adjust. Journal Line";

    layout
    {
        area(Content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = All;
                Caption = 'Batch Name';
                Lookup = true;

                trigger OnLookup(var Text: Text): Boolean;
                begin
                    CurrPage.SaveRecord();
                    CashManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate();
                begin
                    CashManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Lines)
            {
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate();
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        CashManagement.GetAccounts(Rec, AccName);
                        CurrPage.Update();
                    end;
                }
                field("G/L Account Name"; Rec."G/L Account Name")
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
            }
            group(Group)
            {
                fixed("Fixed Group")
                {
                    group("Account Name")
                    {
                        Caption = 'Account Name';
                        field(AccName; AccName)
                        {
                            ApplicationArea = All;
                            Editable = false;
                        }
                    }
                    group(BalanceAmt)
                    {
                        Caption = 'Total Balance';
                        field(Balance; Balance + Rec."Balance (LCY)" - xRec."Balance (LCY)")
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Balance';
                            Editable = false;
                            Visible = BalanceVisible;
                        }
                    }
                    group("Total Balance")
                    {
                        Caption = 'Total Balance';
                        field(TotalBalance; TotalBalance + Rec."Balance (LCY)" - xRec."Balance (LCY)")
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Balance';
                            Editable = false;
                            Visible = TotalBalanceVisible;
                        }
                    }
                }
            }
        }
        area(FactBoxes)
        {
            part(DimensionFact; 699)
            {
                SubPageLink = "Dimension Set ID" = field("Dimension Set ID");
                Visible = false;
                ApplicationArea = All;
            }
            systempart(LinksFact; Links)
            {
                Visible = false;
                ApplicationArea = All;
            }
            systempart(NotesFact; Notes)
            {
                Visible = false;
                ApplicationArea = All;
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
                    CurrPage.SaveRecord();
                end;
            }
        }
        area(Processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Post Journal")
                {
                    Caption = 'Post Journal';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortcutKey = 'F9';
                    ApplicationArea = All;

                    trigger OnAction();
                    begin
                        CashManagement.PostAdjustmentJournal(Rec);
                    end;
                }
                action("Calculate Cash")
                {
                    Caption = 'Calculate Cash';
                    Image = Calculate;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = report "SLGI CSH Calculate Cash Basis";
                    ShortcutKey = 'F11';
                    ApplicationArea = All;
                }
            }
            group(Account)
            {
                Caption = 'Account';
                Image = ChartOfAccounts;
                action(Card)
                {
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = page "G/L Account Card";
                    RunPageLink = "No." = field("G/L Account No.");
                    ShortcutKey = 'Shift+F7';
                    ApplicationArea = All;
                }
                action("Ledger Entries")
                {
                    Caption = 'Ledger Entries';
                    Image = GLRegisters;
                    Promoted = false;
                    RunObject = page "SLGI Cash G/L Entries";
                    RunPageLink = "G/L Account No." = field("G/L Account No.");
                    ShortcutKey = 'Ctrl+F7';
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord();
    begin
        CashManagement.GetAccounts(Rec, AccName);
        UpdateBalance();
    end;

    trigger OnAfterGetRecord();
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit();
    begin
        TotalBalanceVisible := true;
        BalanceVisible := true;
    end;

    trigger OnModifyRecord(): Boolean;
    begin
    end;

    trigger OnNewRecord(BelowxRec: Boolean);
    begin
        UpdateBalance();
        Rec.SetUpNewLine(xRec, Balance, BelowxRec);
        Clear(ShortcutDimCode);
        Clear(AccName);
    end;

    trigger OnOpenPage();
    begin
        CurrentJnlBatchName := Rec."Journal Batch Name";
        CashManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        CashManagement: Codeunit "SLGI Cash Basis Mgmt";
        CurrentJnlBatchName: Code[10];
        AccName: Text[100];
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        ShortcutDimCode: array[8] of Code[20];
        // [InDataSet]
        BalanceVisible: Boolean;
        // [InDataSet]
        TotalBalanceVisible: Boolean;

    local procedure UpdateBalance();
    begin
        CashManagement.CalcBalance(Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
        BalanceVisible := ShowBalance;
        TotalBalanceVisible := ShowTotalBalance;
    end;

    local procedure CurrentJnlBatchNameOnAfterVali();
    begin
        CurrPage.SaveRecord();
        CashManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

}

