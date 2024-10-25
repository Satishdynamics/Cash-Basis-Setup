table 50053 "SLGI Cash Adjust. Jnl Batch"
{
    Caption = 'Cash Adjustment Journal Batch';
    DataClassification = CustomerContent;
    DataCaptionFields = Name, Description;
    LookupPageId = "SLGI Cash Adjust Jnl Batches";

    fields
    {
        field(2; Name; Code[10])
        {
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Reason Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(7; "No. Series"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(10; "Allow Jnl. out of Balance"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Name)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete();
    begin
        CashAdjustJnlLine.SetRange("Journal Batch Name", Name);
        CashAdjustJnlLine.DeleteAll(true);
    end;

    var
        CashAdjustJnlLine: Record "SLGI Cash Adjust. Journal Line";

    local procedure CheckGLAcc(AccNo: Code[20]);
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
            GLAcc.TestField("Direct Posting", true);
        end;
    end;

    procedure ModifyLines(i: Integer);
    var
        CashJnlLine: Record "SLGI Cash Adjust. Journal Line";
    begin
        CashJnlLine.LockTable;
        CashJnlLine.SetRange("Journal Batch Name", Name);
        if CashJnlLine.FindSet then
            repeat
                case i of
                    FieldNo("Reason Code"):
                        CashJnlLine.Validate("Reason Code", "Reason Code");
                end;
                CashJnlLine.Modify(true);
            until CashJnlLine.Next = 0;
    end;
}

