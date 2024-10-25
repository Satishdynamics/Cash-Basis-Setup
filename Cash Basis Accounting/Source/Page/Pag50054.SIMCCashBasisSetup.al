page 50054 "SLGI Cash Basis Setup"
{
    Caption = 'Cash Basis Setup';
    PageType = Card;
    UsageCategory = Administration;
    ApplicationArea = All;
    SourceTable = "SLGI Cash Basis Setup";
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Retained Earnings"; Rec."Retained Earnings")
                {
                    ApplicationArea = All;
                }
                field("Overpayment Account"; Rec."Overpayment Account")
                {
                    ApplicationArea = All;
                }
                field("Ignore Before Date"; Rec."Ignore Before Date")
                {
                    ApplicationArea = All;
                }
                field("Do Not Delete Before Date"; Rec."Do Not Delete Before Date")
                {
                    ApplicationArea = All;
                }
                field("Allow Exclude Cash Editable"; Rec."Allow Exclude Cash Editable")
                {
                    ApplicationArea = All;
                    ToolTip = 'If checked, the field "Exclude in Cash" will be editable in General Journals. If not, the field is not editable.';
                }
                field("Allow Doc. Posting in G/L Jnl."; Rec."Allow Doc. Posting in G/L Jnl.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'No longer needed';
                }
            }

            group(License)
            {
                Caption = 'License';
                field("Exp Date"; Rec."Exp Date")
                {
                    ApplicationArea = All;
                }
                field("Trl Period"; Rec."Trl Period")
                {
                    ApplicationArea = All;
                }
                field("Lic Company Name"; Rec."Lic Company Name")
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
            group(Subscription)
            {
                Caption = 'Subscription';
                ToolTip = 'Subscription activation';
                Image = CreateBinContent;
                action(ActivateSubscription)
                {
                    Caption = 'Activate Subscription';
                    ToolTip = 'Start the activation process of the subscription.';
                    ApplicationArea = All;
                    Image = ActivateDiscounts;
                    trigger OnAction()
                    var
                    //SubPage: Page "SLGI SUB Activation";
                    begin
                        //SubPage.SetAppCode('CSH');
                        //SubPage.RunModal();
                        //Clear(SubPage);
                    end;
                }
                action(ActivateMultipleSubscription)
                {
                    Caption = 'Activate Multiple Subscriptions';
                    ToolTip = 'Start the activation process of multiple company subscriptions.';
                    ApplicationArea = All;
                    Image = ActivateDiscounts;
                    trigger OnAction()
                    var
                    //SubPage: Page "SLGI SUB Company Licenses";
                    begin
                        // Clear(SubPage);
                        //SubPage.SetAppCode('CSH');
                        // SubPage.RunModal();
                    end;
                }
                action(InitLicenseSetup)
                {
                    Caption = 'Initialize License and Setup';
                    ToolTip = 'Will initialize license and setup';
                    ApplicationArea = All;
                    Image = CreateElectronicReminder;
                    trigger OnAction()
                    var
                    //SlgCrestSub: Codeunit "SLGI SUB Subscription";
                    begin
                        //if Confirm('Initialize license and setup?') then begin
                        // Rec.CreateStandardSetup();
                        // SlgCrestSub.CreateTrialLicense('CSH', 'Cash Basis', CalcDate('<30D>', Today()));
                        //end;
                    end;
                }
            }
        }
    }
}